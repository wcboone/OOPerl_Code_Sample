#
# Export GSI's GNC GoldCard changes from the GSI database.
#

#
# $Id: Export.pm,v 1.70 2009/12/10 15:17:32 demij Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataTranslate::Simple;
use GSI::DataX::GNC::GoldCard::Files::Export;

use GSI::OptArg::ClassAttr {
#    DATE	=> { MODIFY	=> 1,
#		     DEFAULT	=> { START => '24 hours ago', },
#		   },
};

my $verboseLevel = GSI::Utils::Verbose->get_level();

sub export {
    my $self = shift;
    $self->verbose(1, entrystamp('export', __PACKAGE__));

    my $error = $self->{ERROR};
    my $errorMsg = $self->{MSG};
    if ($error) {
	$self->verbose(1, "Skipping 'export' due to errors.\n");
    }
    else {
	my $opts = {};
	$opts->{DATES}  = $self->{DATES};
	$opts->{CACHED} = 1;

	my $exportSet = GSI::DataX::GNC::GoldCard::Files::Export->new($opts);
	my $exportName = $exportSet->{SET_NAME};
	my $exportPath = $exportSet->new_file->path;

	if (!defined($exportPath) || ($exportPath eq "")) {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error!  $exportName not found\n";
	    $self->verbose(1, "\n!!! $self->{MSG}\n\n");
	    warn("\n!!! $self->{MSG}\n\n");
	}
	else {
	    $self->verbose(1, "Using file \"$exportPath\"\n");
	    $self->_export($exportPath);
	}
    }
    return 1;
}


#
# Private Methods
#

sub _export {
    my $self   = shift;
    my $path   = shift;
    my $store  = $self->{STORE};

    $self->verbose(1, "For store \"$store\"\n");
    $self->verbose(1, "Export GoldCard to file \"$path\"\n");
    $self->verbose(1, "Using database \"", $self->database->name, "\"\n");

    # These are in GoldCard.pm; they are shared between Import, Export, etc.
    my $mlpId	= $self->{MLP_PROGRAM_ID};
    my @gncCols	= @{$self->{GNC_COLS}};

    my $exportSQL = $self->_exportSQL($store);

    my ($queryRows, $exportRows) = (0, 0);
    my $exportMap = [
	   DBQuery	=> { DB_NAME	=> $self->database->name,
			     SQL	=> $exportSQL,
			   }
	=> CountRows	=> { COUNTER	=> \$queryRows, }
	=> Debug	=> { MESSAGE	=> ">>> DBQuery ",
			     USE	=> $verboseLevel > 3,
			   }

	# Birthday fix up.
	=> TextMunge	=> { COLUMN	=> 'BIRTH_MONTH',
			     REGEXP	=> [q#s/\/.*$//#,
					    q#s/^(.)$/0$1/#,
					    q#s/^\s*$/00/# ],
			     UNDEF_OK	=> 1,
			   }
	=> TextMunge	=> { COLUMN	=> 'BIRTH_YEAR',
			     REGEXP	=> [q#s/.*\///#,
					    q#s/^\s*$/0000/# ],
			     UNDEF_OK	=> 1,
			   }

	# County Code -- no fix up.  GNC uses 3 char codes, GSI uses 2 chars,
	# and GNC will handle mapping to GSI codes.

	# Zip Code fix up.
	=> TextMunge	=> { COLUMN	=> 'ZIP_CODE',
			     REGEXP	=> q#s/^(.{5}).*$/$1/#,
			   }
	=> TextMunge	=> { COLUMN	=> 'ZIP_EXTENSION',
			     REGEXP	=> [q#s/^.{5}//#,
					    q#s/^\s*$/0000/#,],
			   }

	# Phone number fix up.
	=> TextMunge	=> { COLUMNS	=> 'PHONE_NUMBER',
			     REGEXP	=> [q#s/^() -$//#,
					    q#s/[^\d]//g#,],
			   }
# this rowadd/textexpand would have been better as a copycol		#todo
	=> RowAdd	=> { VALUES	=> {
			PHONE_NUMBER_AREA_CODE	=> '${PHONE_NUMBER}',
			PHONE_NUMBER_PREFIX	=> '${PHONE_NUMBER}',
			PHONE_NUMBER_SUFFIX	=> '${PHONE_NUMBER}',
					   },
			   }
	=> TextExpand	=> { COLUMNS	=> [qw/PHONE_NUMBER_AREA_CODE
					       PHONE_NUMBER_PREFIX
					       PHONE_NUMBER_SUFFIX/],
			   }
	=> TextMunge	=> { COLUMN	=> 'PHONE_NUMBER_AREA_CODE',
			     REGEXP	=> q#s/^(\d{3}).*/$1/#,
			   }
	=> TextMunge	=> { COLUMN	=> 'PHONE_NUMBER_PREFIX',
			     REGEXP	=> q#s/^(\d{3})(\d{3}).*/$2/#,
			   }
	=> TextMunge	=> { COLUMN	=> 'PHONE_NUMBER_SUFFIX',
			     REGEXP	=> q#s/^(\d{3})(\d{3})(\d{4}).*/$3/#,
			   }
	# Email Opt-In fix up.  Refer to notes from Brian Collery @ GNC, in
	# the perldoc, below.
# below logic is now taken directly from database  SMP 3900
#	=> [  ColumnMatch		=> { COLUMN	=> 'EMAIL_OPTIN_FLAG',
#					     MATCH	=> 'Y',
#					   }
#	   # OPTIN == Y
#	   => RowAdd	=> { VALUES	=> { DO_NOT_MAIL_FLAG		=> 'N',
#					     DO_NOT_RENT_FLAG		=> 'N',
#					     DO_NOT_TELEMARKET_FLAG	=> 'Y',
#					   },
#			   }
#	   ]
#	=> [  ColumnNotMatch		=> { COLUMN	=> 'EMAIL_OPTIN_FLAG',
#					     MATCH	=> 'Y',
#					   }
#	   # OPTIN != Y
#	   => [  ColumnMatch		=> { COLUMN	=> 'GSI_REASON',
#					     MATCH	=> 'C',
#					   }
#	      # Catalog requests with OPTIN != Y
#	      => RowAdd	=> { VALUES	=> { DO_NOT_MAIL_FLAG		=> 'N',
#					     DO_NOT_RENT_FLAG		=> 'N',
#					     DO_NOT_TELEMARKET_FLAG	=> 'Y',
#					     EMAIL_OPTIN_FLAG		=> 'Y',
#					   },
#			   }
#	      ]
#	   => [  ColumnNotMatch		=> { COLUMN	=> 'GSI_REASON',
#					     MATCH	=> 'C',
#					   }
#	      # Non-catalog requests with OPTIN != Y (could be 'N' or ' ')
#	      => RowAdd	=> { VALUES	=> { DO_NOT_MAIL_FLAG		=> 'Y',
#					     DO_NOT_RENT_FLAG		=> 'Y',
#					     DO_NOT_TELEMARKET_FLAG	=> 'Y',
#					     EMAIL_OPTIN_FLAG		=> 'N',
#					   },
#			   }
#	      ]
#	   ]

	# Customer Preferences fix up.  Expand from 'a|c|d' to columns
	# named A, C, D with values 'Y' and add a single blank for
	# all other columns (e.g. missing 'b', 'e', etc. columns).
	=> TextMunge	=> { COLUMN	=> 'CUSTOMER_PREFS',
			     REGEXP	=> q#s/(.*)/\U$1/g#,
			   }
	=> SplitToCols	=> { COLUMN	=> 'CUSTOMER_PREFS',
			     PATTERN	=> '\|',
			   }

	=> [ColumnMatch	=> { COLUMN	=> 'CUSTOMER_PREF_BONE_JOINT_HEALTH',
			     MATCH	=> undef,
			   }
	   => RowAdd	=> { VALUES	=> {
				    CUSTOMER_PREF_BONE_JOINT_HEALTH => ' ',
					   },
			   }
	   ]
	=> [ColumnMatch	=> { COLUMN	=> 'CUSTOMER_PREF_FITNESS_STRENGTH',
			     MATCH	=> undef,
			   }
	   => RowAdd	=> { VALUES	=> {
				    CUSTOMER_PREF_FITNESS_STRENGTH => ' ',
					   },
			   }
	   ]
	=> [ColumnMatch	=> { COLUMN	=> 'CUSTOMER_PREF_HEART_HEALTH',
			     MATCH	=> undef,
			   }
	   => RowAdd	=> { VALUES	=> {
				    CUSTOMER_PREF_HEART_HEALTH => ' ',
					   },
			   }
	   ]
	=> [ColumnMatch	=> { COLUMN	=> 'CUSTOMER_PREF_NATURAL_REMEDIES',
			     MATCH	=> undef,
			   }
	   => RowAdd	=> { VALUES	=> {
				    CUSTOMER_PREF_NATURAL_REMEDIES => ' ',
					   },
			   }
	   ]
	=> [ColumnMatch	=> { COLUMN	=> 'CUSTOMER_PREF_VITAMINS',
			     MATCH	=> undef,
			   }
	   => RowAdd	=> { VALUES	=> {
				    CUSTOMER_PREF_VITAMINS => ' ',
					   },
			   }
	   ]
	=> [ColumnMatch	=> { COLUMN	=> 'CUSTOMER_PREF_WEIGHT_LOSS_LOW_CARB',
			     MATCH	=> undef,
			   }
	   => RowAdd	=> { VALUES	=> {
				    CUSTOMER_PREF_WEIGHT_LOSS_LOW_CARB => ' ',
					   },
			   }
	   ]

	#  Reason fix up.
	=> TextMunge	=> { COLUMN	=> 'GSI_REASON',
			     REGEXP	=> [q#s/(create|renew)/P/#,
					    q#s/^\s*$/U/#],
			     UNDEF_OK	=> 1,
			   }
	=> [  ColumnNotMatch	=> { COLUMN	=> 'GSI_REASON',
				     MATCH	=> qr/[CEP]/,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'GNC_GOLD_CARD_NBR',
				     MATCH	=> undef,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'PHONE_NUMBER',
				     MATCH	=> qr/^\s*$/,
				   }
	   # Z = non-GC account, see perldoc below
	   => RowAdd		=> { VALUES	=> { GSI_REASON => 'Z', },
				   }
	   ]
	=> [  ColumnMatch	=> { COLUMN	=> 'GSI_REASON',
				     MATCH	=> 'U',
				   }
	   => RowAdd		=> { VALUES	=> { GSI_SHIP_DT => ' ', },
				   }
	   ]
	# Discard email-only records with bad or empty email address.
	=> [  ColumnMatch	=> { COLUMN	=> 'GSI_REASON',
				     MATCH	=> qr/E/,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'EMAIL_ADDRESS',
				     MATCH	=> qr/.+@.+\..+/,
				     UNDEF_UP	=> 1,
				   }
	   ]
	# Discard catalog-only records with bad email address (but empty is ok).
	=> [  ColumnMatch	=> { COLUMN	=> 'GSI_REASON',
				     MATCH	=> qr/C/,
				   }
	   => ColumnNotMatch	=> { COLUMN	=> 'EMAIL_ADDRESS',
				     MATCH	=> [qr/^ *$/]
				   }
	   => ColumnMatch	=> { COLUMN	=> 'EMAIL_ADDRESS',
				     MATCH	=> qr/.+@.+\..+/,
				     UNDEF_UP	=> 1,
				   }
	   ]
	# Discard catalog-only records without valid mailing address.
	# This is a "can't happen" situation because these fields are required
	# during the catalog request dialog.  Still, they exist in the database:
	# e.g. account_id = 956960011 dated 12/28/2006.
	=> [  ColumnMatch	=> { COLUMN	=> 'GSI_REASON',
				     MATCH	=> qr/C/,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'LAST_NAME',
				     MATCH	=> [qr/\S+/],
				     UNDEF_UP	=> 1,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'FIRST_NAME',
				     MATCH	=> [qr/\S+/],
				     UNDEF_UP	=> 1,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'STREET_ADDRESS',
				     MATCH	=> [qr/\S+/],
				     UNDEF_UP	=> 1,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'STATE',
				     MATCH	=> [qr/\S+/],
				     UNDEF_UP	=> 1,
				   }
	   => ColumnMatch	=> { COLUMN	=> 'ZIP_CODE',
				     MATCH	=> [qr/\S+/],
				     UNDEF_UP	=> 1,
				   }
	   ]

	# Trim leading and trailing whitespace, map empty string to single space.
	=> TextMunge	=> { COLUMN	=> [qw/GNC_GOLD_CARD_NBR
					       CITY
					       EMAIL_ADDRESS
					       GENDER
					       FIRST_NAME
					       LAST_NAME
					       MAGAZINE_PREFERENCE
					       MIDDLE_INITIAL
					       PHONE_NUMBER_AREA_CODE
					       PHONE_NUMBER_PREFIX
					       PHONE_NUMBER_SUFFIX
					       STREET_ADDRESS
					       GSI_MOD_DT
					       GSI_SHIP_DT
					       GSI_EXP_DT/],
			     REGEXP	=> [q#s/^\s*//#,
					    q#s/\s*$//#,
					    q#s/^\s*$/ /#,],
			     UNDEF_OK	=> 1,
			   }

	# Column name fix up.
	=> RenameCol	=> { MAP => {
		GSI_MOD_DT  => 'GSI_RECORD_MODIFIED_DATE',
		GSI_REASON  => 'GSI_REASON_CARD_PURCHASED_RENEWED_OR_UPDATED',
		GSI_SHIP_DT => 'GSI_SHIPPED_DATE_4_CARD_PURCHASED_OR_RENEWED',
		GSI_EXP_DT  => 'GSI_GNC_GOLD_CARD_EXPIRATION_DATE',
				    },
			   }

	=> IgnoreDups	=> { KEY	=> [qw/GNC_GOLD_CARD_NBR
					       GSI_BILL_TO_NBR/],
			   }
	=> [  ColumnNotMatch	=> { COLUMN	=> 'GNC_GOLD_CARD_NBR',
				     MATCH	=> ' ',
				   }
	   => IgnoreDups	=> { KEY	=> [qw/GNC_GOLD_CARD_NBR/],
				     UNDEF_UP	=> 1,
				   }
	   ]
#
# Ticket 60916 Truncate fields to screen based lengths
#
        => TextMunge    => { COLUMN => 'GNC_GOLD_CARD_NBR',
			     REGEXP	=> q#s/^(\S{12}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'GSI_BILL_TO_NBR',
			     REGEXP	=> q#s/^(\S{12}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'BIRTH_MONTH',
			     REGEXP	=> q#s/^(\S{2}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'BIRTH_YEAR',
			     REGEXP	=> q#s/^(\S{4}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CITY',
			     REGEXP	=> q#s/^(\S{30}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CITY',
			     REGEXP	=> q#s/\t//g#,
                           }

        => ConvertToAscii => { COLUMN => "CITY" }

        => TextMunge    => { COLUMN => 'COUNTRY',
			     REGEXP	=> q#s/^(\S{3}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CUSTOMER_PREF_BONE_JOINT_HEALTH',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CUSTOMER_PREF_FITNESS_STRENGTH',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CUSTOMER_PREF_HEART_HEALTH',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CUSTOMER_PREF_NATURAL_REMEDIES',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CUSTOMER_PREF_VITAMINS',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'CUSTOMER_PREF_WEIGHT_LOSS_LOW_CARB',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'DO_NOT_MAIL_FLAG',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'DO_NOT_RENT_FLAG',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'DO_NOT_TELEMARKET_FLAG',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'EMAIL_ADDRESS',
			     REGEXP	=> q#s/^(\S{100}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'EMAIL_OPTIN_FLAG',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'FIRST_NAME',
			     REGEXP	=> q#s/^(\S{20}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'FIRST_NAME',
			     REGEXP	=> q#s/\t//g#,
                           }

        => ConvertToAscii => { COLUMN => "FIRST_NAME" }

        => TextMunge    => { COLUMN => 'GENDER',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'LAST_NAME',
			     REGEXP	=> q#s/^(\S{30}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'LAST_NAME',
			     REGEXP	=> q#s/\t//g#,
                           }

        => ConvertToAscii => { COLUMN => "LAST_NAME" }

        => TextMunge    => { COLUMN => 'MAGAZINE_PREFERENCE',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'MIDDLE_INITIAL',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'STATE',
			     REGEXP	=> q#s/^(\S{2}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'STREET_ADDRESS',
			     REGEXP	=> q#s/^(\S{50}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'STREET_ADDRESS',
			     REGEXP	=> q#s/\t//g#,
                           }

        => ConvertToAscii => { COLUMN => "STREET_ADDRESS" }

        => TextMunge    => { COLUMN => 'GSI_RECORD_MODIFIED_DATE',
			     REGEXP	=> q#s/^(\S{10}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'GSI_REASON_CARD_PURCHASED_RENEWED_OR_UPDATED',
			     REGEXP	=> q#s/^(\S{1}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'GSI_SHIPPED_DATE_4_CARD_PURCHASED_OR_RENEWED',
			     REGEXP	=> q#s/^(\S{10}).*/$1/#,
                           }

        => TextMunge    => { COLUMN => 'GSI_GNC_GOLD_CARD_EXPIRATION_DATE',
			     REGEXP	=> q#s/^(\S{10}).*/$1/#,

                           }
        => TextMunge    => { COLUMN     => 'ZIP_CODE',
                             REGEXP     => q#s/^(\S{5}).*$/$1/#,
                           }

        => TextMunge    => { COLUMN     => 'ZIP_EXTENSION',
                             REGEXP     => q#s/^(\S{4}).*$/$1/#,
                           }

	=> Debug	=> { MESSAGE	=> ">>> Delimited ",
			     USE	=> $verboseLevel > 3,
			   }
	=> CountRows	=> { COUNTER	=> \$exportRows, }
	=> Delimited	=> { FILE_NAME	=> $path,
			     HEADER	=> 0,
			     NEWLINE	=> "\r\n",
			     COLUMNS	=> \@gncCols,
			     ZERO_ROWS_REMOVE => 0,
			   }
    ]; # end of exportMap
    translate($exportMap);

    $self->{TOTAL_COUNT} = $exportRows;
    $self->verbose(3, "$store GoldCard pulled $queryRows rows from database.\n");
    $self->verbose(1, "$store GoldCard file has $exportRows rows.\n");
}


sub _exportSQL {
    my $self = shift;
    my $store = shift;

    my $mlpId	 = $self->{MLP_PROGRAM_ID};
    my $dates	 = $self->{DATES};
    my $usequery = $self->{USE_QUERY};
    my $tags	 = $self->effective_test_tags;

    my ($dateSQL_GC, $dateSQL_nonGC, $dateSQL_trans) = ('', '', '');
    if (defined $dates) {
	$dateSQL_GC .= "\n\tAND (" .
		    "\n\t   " . $dates->sql('ma.date_modified') .
#		    "\n\tOR " . $dates->sql('ma.date_added') .
		    "\n\tOR " . $dates->sql('mca.date_modified') .
#		    "\n\tOR " . $dates->sql('mca.date_added') .
#		    "\n\tOR " . $dates->sql('c.status_date') .
		      ")";
	$dateSQL_nonGC .= "\n\tAND (" .
		    "\n\t   " . $dates->sql('c.status_date') . ")";
	$dateSQL_trans .= "\n\tAND (" .
		    "\n\t   " . $dates->sql('mt.start_date', ' (+)') . ")";
    }
    my $rowsSQL = '' . do { "\n\tAND rownum < 5" if (defined $tags->{ROWNUM})};
    my $userIdSQL = $self->_userIdSQL();
    my $accountIdSQL = $self->_accountIdSQL();

    # The mlp_account_attrib aliases are:
    #	mlp_account_attrib	maa_db,	-- GCDateOfBirth
    #	mlp_account_attrib	maa_ic,	-- GCInterestCats, aka CUSTOMER_PREF_*
    #	mlp_account_attrib	maa_mp,	-- GCMagPrefs
    #	mlp_account_attrib	maa_g,	-- GCGender
    #	mlp_account_attrib	maa_mi,	-- GCMiddleInitial

    # Must ensure all these are pulled:
    # a) GC member and customer of GNC store
    # b) non-GC member and customer of GNC store
    # b) email-only guest of GNC store


###
### Note:  The single large UNION "exportSQL" was split into three
###        to exploit parallelism and reduce run-time.
###

    my $P1SQL = <<"END_P1EXPORT_SQL";
    SELECT
    -- GoldCard customers --
	ma.account_id					GNC_GOLD_CARD_NBR,
	mca.user_id					GSI_BILL_TO_NBR,
	maa_db.attrib_text				BIRTH_MONTH,
	maa_db.attrib_text				BIRTH_YEAR,
	SUBSTR(ma.city, 1, 30)				CITY,
	ma.country_code					COUNTRY,
	maa_ic.attrib_text				CUSTOMER_PREFS,
	SUBSTR(ma.email, 1, 100)			EMAIL_ADDRESS,
	ma.email_preference				EMAIL_OPTIN_FLAG,
	decode ( ( select ci.response from cust_info ci
			where c.user_id = ci.user_id
			  and ci.question_code = 'emailPref'
		  ) || '#' || 
		 ( select ci.response from cust_info ci
			where c.user_id = ci.user_id
			  and ci.question_code = 'contest'
	         ),'N#GNC_catalog_unsubscribe','Y','N') DO_NOT_MAIL_FLAG,
	' '						DO_NOT_RENT_FLAG,
	' '						DO_NOT_TELEMARKET_FLAG,
	SUBSTR(ma.first_name, 1, 20)			FIRST_NAME,
	maa_g.attrib_text				GENDER,
	SUBSTR(ma.last_name, 1, 30)			LAST_NAME,
	maa_mp.attrib_text				MAGAZINE_PREFERENCE,
	maa_mi.attrib_text				MIDDLE_INITIAL,

--real	NVL(ma.phone_day, ' ')				PHONE_NUMBER,	--
--temp...
-- the "() -" check is a temp hack due to bad data loaded in staging2 by --
-- an old  import feed.  not needed afer new import feed or in production--
	DECODE(ma.phone_day,   '() -',	NULL,
					ma.phone_day)	PHONE_NUMBER,

	ma.state_code					STATE,
	SUBSTR(ma.address1 || ' ' || ma.address2,
	       1, 50)					STREET_ADDRESS,
	NVL(ma.postal_code, '00000')			ZIP_CODE,
	NVL(ma.postal_code, '0000')			ZIP_EXTENSION,
	TO_CHAR(GREATEST(ma.date_modified,
			 mca.date_modified),
		'MM/DD/YYYY HH24:MI')			GSI_MOD_DT,
	mt.trans_type					GSI_REASON,
	TO_CHAR(NVL(ma.date_modified,
		    ma.date_added), 'MM/DD/YYYY HH24:MI')	GSI_SHIP_DT,
	TO_CHAR(ma.expiry_date, 'MM/DD/YYYY')		GSI_EXP_DT
    FROM
	customer		c,
	mlp_account		ma,
	mlp_account_attrib	maa_db,
	mlp_account_attrib	maa_ic,
	mlp_account_attrib	maa_mp,
	mlp_account_attrib	maa_g,
	mlp_account_attrib	maa_mi,
	mlp_customer_account	mca,
	mlp_trans		mt
    WHERE
	    ma.program_id	= $mlpId
	AND ma.account_id	NOT LIKE 'TMP%'
	AND ma.program_id	= mca.program_id (+)
	AND ma.account_id	= mca.account_id (+)
	AND ma.program_id	= mt.program_id (+)
	AND ma.account_id	= mt.account_id (+)
	AND mt.trans_status (+)	= 'A'
	AND mca.user_id		= c.user_id
	AND c.store_code (+)	= '$store'
	AND c.status		= 'ACTIVE'
	AND ( (     maa_db.attrib_tag (+) = 'GCDateOfBirth'
		AND maa_db.account_id (+) =  ma.account_id
		AND maa_db.program_id (+) =  ma.program_id )
	  AND (     maa_ic.attrib_tag (+) = 'GCInterestCats'
		AND maa_ic.account_id (+) =  ma.account_id
		AND maa_ic.program_id (+) =  ma.program_id )
	  AND (     maa_mp.attrib_tag (+) = 'GCMagPrefs'
		AND maa_mp.account_id (+) =  ma.account_id
		AND maa_mp.program_id (+) =  ma.program_id )
	  AND (     maa_g.attrib_tag  (+) = 'GCGender'
		AND maa_g.account_id  (+) =  ma.account_id
		AND maa_g.program_id  (+) =  ma.program_id )
	  AND (     maa_mi.attrib_tag (+) = 'GCMiddleInitial'
		AND maa_mi.account_id (+) =  ma.account_id
		AND maa_mi.program_id (+) =  ma.program_id )
	    )
DDDDDDDDDD
IIIIIIIIII
UUUUUUUUUU
RRRRRRRRRR
TTTTTTTTTT
END_P1EXPORT_SQL

    my $P2SQL = <<"END_P2EXPORT_SQL";
    SELECT
    -- non-GoldCard customers; excludes both email-only guests	--
    -- and catalog-only guests.					--
	NULL						GNC_GOLD_CARD_NBR,
	c.user_id					GSI_BILL_TO_NBR,
	DECODE(c.birthday,
		NULL,	'00',
			TO_CHAR(c.birthday, 'MM'))	BIRTH_MONTH,
	DECODE(c.birthday,
		NULL,	'0000',
			TO_CHAR(c.birthday, 'YYYY'))	BIRTH_YEAR,
	SUBSTR(NVL(cca.city, ' '), 1, 30)		CITY,
	NVL(cca.country_code, ' ')			COUNTRY,
	NULL						CUSTOMER_PREFS,
	SUBSTR(NVL(c.email, ' '), 1, 100)		EMAIL_ADDRESS,
	NVL(c.email_pref_code, 'Y')			EMAIL_OPTIN_FLAG,
	decode ( ( select ci.response from cust_info ci
			where c.user_id = ci.user_id
			  and ci.question_code = 'emailPref'
		  ) || '#' || 
		 ( select ci.response from cust_info ci
			where c.user_id = ci.user_id
			  and ci.question_code = 'contest'
	         ),'N#GNC_catalog_unsubscribe','Y','N') DO_NOT_MAIL_FLAG,
	' '						DO_NOT_RENT_FLAG,
	' '						DO_NOT_TELEMARKET_FLAG,
	SUBSTR(NVL(cca.first_name, c.user_first_name),
	       1, 20)					FIRST_NAME,
	NVL(c.sex, ' ')					GENDER,
	SUBSTR(NVL(cca.last_name, c.user_last_name),
	       1, 30)					LAST_NAME,
	NULL						MAGAZINE_PREFERENCE,
	SUBSTR(NVL(cca.middle_name, ' '), 1, 1)		MIDDLE_INITIAL,
	NVL(cca.address_phone, NVL(c.phone_day, ' '))	PHONE_NUMBER,
	NVL(cca.state_code, ' ')			STATE,
	SUBSTR(cca.address1 || ' ' || cca.address2,
	       1, 50)					STREET_ADDRESS,
	NVL(cca.postalcode, '00000')			ZIP_CODE,
	NVL(cca.postalcode, '0000')			ZIP_EXTENSION,
	TO_CHAR(NVL(c.datetime_updated,
		    NVL(c.datetime_created,
			c.status_date)),
		'MM/DD/YYYY HH24:MI')			GSI_MOD_DT,
	DECODE(c.guest,
	       1,	DECODE(c.last_purchase_date,
			       NULL,	'E',
					'U'),
			'U')				GSI_REASON,
	NULL						GSI_SHIP_DT,
	NULL						GSI_EXP_DT
    FROM
	customer		c,
	cc_address		cca
    WHERE
	    c.store_code	= '$store'
	AND c.status		= 'ACTIVE'
	AND c.default_cc	= cca.cc_address_id (+)
--ok?	AND cca.status	       != 'INACTIVE' --
--	AND cca.status		IS NULL --
	AND (    c.last_purchase_date IS NOT NULL
	      OR (     c.last_purchase_date IS NULL
		   AND NOT EXISTS ( SELECT 1
				    FROM   cust_info ci1
				    WHERE  ci1.user_id = c.user_id )
		 )
	    )
	AND NOT EXISTS ( SELECT	1
			 FROM	mlp_customer_account	mca1,
				mlp_trans		mt1
			 WHERE	    mca1.program_id	= $mlpId
				AND mca1.user_id	= c.user_id
				AND mt1.account_id (+)	= mca1.account_id )
EEEEEEEEEE
UUUUUUUUUU
RRRRRRRRRR
END_P2EXPORT_SQL

    my $P3SQL = <<"END_P3EXPORT_SQL";
    SELECT
    -- Email-only and catalog-only guests. --
	NULL						GNC_GOLD_CARD_NBR,
	c.user_id					GSI_BILL_TO_NBR,
	'00'						BIRTH_MONTH,
	'0000'						BIRTH_YEAR,
	SUBSTR(NVL(ci_city.response, ' '), 1, 30)	CITY,
	NVL(ci_country.response, ' ')			COUNTRY,
	NULL						CUSTOMER_PREFS,
	SUBSTR(NVL(c.email, ' '), 1, 100)		EMAIL_ADDRESS,
	NVL(c.email_pref_code, 'Y')                     EMAIL_OPTIN_FLAG,
	decode ( ( select ci.response from cust_info ci
			where c.user_id = ci.user_id
			  and ci.question_code = 'emailPref'
		  ) || '#' || 
		 ( select ci.response from cust_info ci
			where c.user_id = ci.user_id
			  and ci.question_code = 'contest'
	         ),'N#GNC_catalog_unsubscribe','Y','N') DO_NOT_MAIL_FLAG,
	' '						DO_NOT_RENT_FLAG,
	' '						DO_NOT_TELEMARKET_FLAG,
	SUBSTR(ci_fname.response, 1, 20)		FIRST_NAME,
	NULL						GENDER,
	SUBSTR(ci_lname.response, 1, 30)		LAST_NAME,
	NULL						MAGAZINE_PREFERENCE,
	NULL						MIDDLE_INITIAL,
	NULL						PHONE_NUMBER,
	NVL(ci_state.response, ' ')			STATE,
	SUBSTR(ci_addr1.response || ' ' ||
	       ci_addr2.response, 1, 50)		STREET_ADDRESS,
	NVL(ci_zip.response, '00000')			ZIP_CODE,
	NVL(ci_zip.response, '0000')			ZIP_EXTENSION,
	TO_CHAR(NVL(c.datetime_updated,
		    NVL(c.datetime_created,
			c.status_date)),
		'MM/DD/YYYY HH24:MI')			GSI_MOD_DT,
	DECODE(ci_zip.response,		NULL,	'E',
						'C')	GSI_REASON,
	NULL						GSI_SHIP_DT,
	NULL						GSI_EXP_DT
    FROM
	customer		c,
	cust_info		ci_city,
	cust_info		ci_country,
	cust_info		ci_fname,
	cust_info		ci_lname,
	cust_info		ci_state,
	cust_info		ci_addr1,
	cust_info		ci_addr2,
	cust_info		ci_zip
    WHERE
	    c.store_code	= '$store'
	AND c.status		= 'ACTIVE'
	AND c.guest		= 1
	AND c.last_purchase_date IS NULL
	AND NOT EXISTS ( SELECT	1
			 FROM	mlp_customer_account	mca1,
				mlp_trans		mt1
			 WHERE	    mca1.program_id	= $mlpId
				AND mca1.user_id	= c.user_id
				AND mt1.account_id (+)	= mca1.account_id )
	AND ( (     ci_city.question_code	(+) = 'city'
		AND ci_city.response		(+) IS NOT NULL
		AND ci_city.user_id		(+) =  c.user_id )
	  AND (     ci_country.question_code	(+) = 'country'
		AND ci_country.response		(+) IS NOT NULL
		AND ci_country.user_id		(+) =  c.user_id )
	  AND (     ci_fname.question_code	(+) = 'fName'
		AND ci_fname.response		(+) IS NOT NULL
		AND ci_fname.user_id		(+) =  c.user_id )
	  AND (     ci_lname.question_code	(+) = 'lName'
		AND ci_lname.response		(+) IS NOT NULL
		AND ci_lname.user_id		(+) =  c.user_id )
	  AND (     ci_state.question_code	(+) = 'state'
		AND ci_state.response		(+) IS NOT NULL
		AND ci_state.user_id		(+) =  c.user_id )
	  AND (     ci_addr1.question_code	(+) = 'addr1'
		AND ci_addr1.response		(+) IS NOT NULL
		AND ci_addr1.user_id		(+) =  c.user_id )
	  AND (     ci_addr2.question_code	(+) = 'addr2'
		AND ci_addr2.response		(+) IS NOT NULL
		AND ci_addr2.user_id		(+) =  c.user_id )
	  AND (     ci_zip.question_code	(+) = 'zip'
		AND ci_zip.response		(+) IS NOT NULL
		AND ci_zip.user_id		(+) =  c.user_id )
	    )
EEEEEEEEEE
UUUUUUUUUU
RRRRRRRRRR
END_P3EXPORT_SQL

    my $UNIONSQL = <<"END_UNION_SQL";

UNION

END_UNION_SQL

    my $ORDERBYSQL = <<"END_ORDERBY_SQL";

ORDER BY
	GNC_GOLD_CARD_NBR,
	GSI_BILL_TO_NBR
END_ORDERBY_SQL

    ####################################################################
    #
    #  Define the exportSQL based upon the usequery flag
    #
    ####################################################################

    my @queryarray = split (/,/, $usequery);
    my $numofcomponents = @queryarray;
    my $component;

    ##################################################
    #
    #  Validate the inputs 
    #
    ##################################################

    if ($numofcomponents > 3) {
       die "Oops ... can only use 3 usequery components\n";
    }

    for ($component=0; $component<$numofcomponents; $component++)
    {
     if (($queryarray[$component] eq '0') or
         ($queryarray[$component] eq '1') or
         ($queryarray[$component] eq '2') or
         ($queryarray[$component] eq '3')) {
     } else {
       die "Oops ... usequery components can only be 1,2,or 3\n";
     }
    }

     if (($numofcomponents == 2) and 
         ($queryarray[0] eq $queryarray[1]))
     {
       die "Oops ... usequery components cannot be duplicated\n";
     }

     if (($numofcomponents == 3) and 
        (($queryarray[0] eq $queryarray[1]) or
         ($queryarray[0] eq $queryarray[2]) or
         ($queryarray[1] eq $queryarray[2])))
     {
       die "Oops ... usequery components cannot be duplicated\n";
     }

    ##################################################
    #
    #  Construct the SQL - default is all 3 parts.
    #
    ##################################################

    my $exportSQL = $P1SQL . $UNIONSQL . $P2SQL . $UNIONSQL . $P3SQL .
      $ORDERBYSQL;

    if ($queryarray[0]) {

       $exportSQL = '';

       for ($component=0; $component<$numofcomponents; $component++)
       {
        if ($component == 1) {
           $exportSQL = $exportSQL . $UNIONSQL;
        }
        if ($component == 2) {
           $exportSQL = $exportSQL . $UNIONSQL;
        }
        if ($queryarray[$component] eq '1') {
           $exportSQL = $exportSQL . $P1SQL;
        }
        if ($queryarray[$component] eq '2') {
           $exportSQL = $exportSQL . $P2SQL;
        }
        if ($queryarray[$component] eq '3') {
           $exportSQL = $exportSQL . $P3SQL;
        }
       }
       $exportSQL = $exportSQL . $ORDERBYSQL;
     }

    ##################################################
    #
    #  Continue SQL construction processing
    #
    ##################################################

    if ($accountIdSQL ne '' or $userIdSQL ne '') {
	# GC account and/or customer account specified, don't pull time range.
	$dateSQL_GC = $dateSQL_nonGC = $dateSQL_trans = '';
    }
    if ($accountIdSQL ne '') {
	# GC account specified, so don't pull non-GC accounts.
#ng, need to change record sep to extent to end of sql
#	$exportSQL =~ s/UNION.*ORDER BY/ORDER BY/;
    }

    $exportSQL =~ s/DDDDDDDDDD/$dateSQL_GC/g;
    $exportSQL =~ s/EEEEEEEEEE/$dateSQL_nonGC/g;
    $exportSQL =~ s/IIIIIIIIII/$accountIdSQL/g;
    $exportSQL =~ s/UUUUUUUUUU/$userIdSQL/g;
    $exportSQL =~ s/RRRRRRRRRR/$rowsSQL/g;
    $exportSQL =~ s/TTTTTTTTTT/$dateSQL_trans/g;

    $self->verbose(2, "exportSQL =\n$exportSQL\n");
    return $exportSQL;
}


use GSI::DBI::DBUtils;

# Generate SQL constraints for a mlp_account.account_id list.
#
sub _accountIdSQL {
    my $self = shift;
    my $accountIds = $self->{ACCOUNT_IDS};

    $self->verbose(3, "ACCOUNT_IDS = ",
		   defined $accountIds ? join(', ', @$accountIds) : '', "\n");

    my $sql = '';
    $sql .= "\n\tAND " . db_in_list('ma.account_id', $accountIds)
		if (defined $accountIds && scalar @$accountIds > 0);
    return $sql;
}


# Generate SQL constraints for a customer.user_id list.
#
sub _userIdSQL {
    my $self = shift;
    my $userIds = $self->{USER_IDS};

    $self->verbose(3, "USER_IDS = ",
		   defined $userIds ? join(', ', @$userIds) : '', "\n");

    my $sql = '';
    $sql .= "\n\tAND " . db_in_list('c.user_id', $userIds)
		if (defined $userIds && scalar @$userIds > 0);
    return $sql;
}

1;

=head1 NAME

GNC Gold Card Data Feed

=head1 SYNOPSIS

Export - Extract Gold Card updates from the database.

=head1 SEE ALSO

Import

=head1 DESCRIPTION

For Email Opt In, 4 values are exchanged with GNC:
	EMAIL_OPTIN_FLAG
	DO_NOT_MAIL_FLAG
	DO_NOT_RENT_FLAG   ( leave blank )
	DO_NOT_TELEMARKET_FLAG   ( leave blank )

Brian Collery @ GNC states:

To the customer there is one question presented in the checkout and can be
updated in My Account (Account Preferences)...

(X) Yes, send me newsletters and update me on sales promotions

mail and rent are now determined independantly ( see database query) smp 3900
  1. mail opt out	
  2. rent opt out		
  3. telemarket opt out		leave blank   # smp 3900 
  4. email opt in		leave blank   # smp 3900


In December 2006 GNC PMO 53991 modified the above slightly for Catalog Requests:
- Set GSI_REASON = 'C'
- Set all *_FLAGS as for A) above


Jun 16 2009 - SMP 3391 changes.
 if opt_out of email (or does not opt_in to email) then switch email flags only ( do not change catalog, rent, or telesales)
 if opt_out of catalog then switch catalog flag to 'No' only ( do not change email , rent, or telesales)


For GSI_REASON_CARD_PURCHASED_RENEWED_OR_UPDATED:

Release 1.0:
P - Gold Card purchased or renewed
U - GC account, or non-GC account with a purchase history
E - Email-only guest:  not a customer -- has never purchased;
    no account details beyond email address (esp. phone number)
C - Catalog requested:  not a customer -- has never purchased;
    account details may be incomplete (esp. email address, which is
    optional on catalog request, but if present may need to examine
    mailing address to discern catalog vs. email; GNC should
    implment these business rules). (added Dec 2006)
Z - non-GC account:  not a customer -- has never purchased;
    account details may be incomplete (usually phone number)


For the catalog-only guest customers, example SQL:

SQL> select ci.*
     from customer c, cust_info ci
     where     c.store_code = 'GNC'
	   and c.user_id = 246525771
	   and c.user_id = ci.user_id;

   USER_ID QUESTION_CODE                              RESPONSE
---------- ------------------------------------------ --------
 246525771 contest                                    GNC_RequestACatalog
 246525771 fName                                      George N.
 246525771 lName                                      Customer
 246525771 addr1                                   98032 PineApple Street
 246525771 city                                    San Diego
 246525771 state                                      CA
 246525771 zip                                        92120
 246525771 email_pref                                 N
 246525771 emailAddress                               gnc@ucsd.edu

10 rows selected.

=item *

=over 4

L<GSI::DataX::Search::Extract>

=back

=head1 AUTHOR

Tom Donohue

=head1 REVISION

$Id: Export.pm,v 1.70 2009/12/10 15:17:32 demij Exp $

=cut
