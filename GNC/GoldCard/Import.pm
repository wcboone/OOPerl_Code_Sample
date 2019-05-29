#
# Import GNC's GoldCard changes to the GSI database.
#
# Inserts Add/Change records Membership Loyality Program (MLP) staging tables
# for GoldCard records received from GNC.  There is no delete logic in this
# feed.  The add vs. change decision is based only on whether the GoldCard
# account exists, not on the account details, so that records from GNC
# always replace ours.
#
# Add/Change records are inserted into two MLP staging tables in the load
# schema:
#   mlp_account_feeds	     -- info common to all or most partners
#   mlp_account_attrib_feeds -- info specific to one or more partners
#
# GNC sends to GSI a weekly inbound feed of changes;  GSI sends to GNC a daily
# outbound feed of changes;  GNC's file is the master.
#
# In the time window between the daily outbound feed and the weekly inbound
# feed, changes a customer makes at the GSI webstore may be lost when the
# inbound feed is loaded.
#

#
# $Id: Import.pm,v 1.44 2007/09/14 20:01:48 wallacej Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use POSIX qw(strftime);

use GSI::DataTranslate::Simple;
use GSI::DataX::GNC::GoldCard::Files::Local;
use GSI::DataX::GNC::GoldCard::Files::ErrorReport;

use GSI::OptArg::ClassAttr {
    DATE	=> { MODIFY	=> 1,
		     DEFAULT	=> { START => '2 days ago', },	#?todo
		   },
};

my $verboseLevel = GSI::Utils::Verbose->get_level();

sub import {
    my $self = shift;
    $self->verbose(1, entrystamp('import', __PACKAGE__));

    my @steps = @{$self->{IMPORT_STEPS}};
    my $whichStep = $self->{WHICH_IMPORT_STEP};
    $self->verbose(1, "\nImport - step # $whichStep = ",
		   $steps[$whichStep], ", of these steps:\n\t",
		   join(', ', @steps), "\n\n");

    my $error = $self->{ERROR};
    my $errorMsg = $self->{MSG};
    if ($error) {
	$self->verbose(1, "Skipping 'import' due to errors.\n");
    }
    else {
	my $opts = {};
	$opts->{DATES}  = $self->{DATES};
	$opts->{CACHED} = 1;

	my ($localSet, $localName, $localPath) = (undef, undef, undef);

	$localPath = $self->{INPUT_FILE} if (defined $self->{INPUT_FILE});

	if (!defined $localPath) {
	    $localSet = GSI::DataX::GNC::GoldCard::Files::Local->existing($opts);
	    if (!defined $localSet  or scalar(@{$localSet->files()}) == 0) {
		$self->{ERROR} = 1;
		$self->{MSG} = "Error!  No GNC Gold Card files found to import.\n";
		warn("\n!!! $self->{MSG}\n\n");
		return 1;
	    }
	    $localName = $localSet->{SET_NAME};
	    $localPath = $localSet->newest()->{PATH};
	}

	if (!defined $localPath or $localPath eq "") {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error!  $localName not found\n";
	    $self->verbose(1, "\n!!! $self->{MSG}\n\n");
	    warn("\n!!! $self->{MSG}\n\n");
	}
	else {
	    $self->verbose(1, "Using file \"$localPath\"\n");
	    $self->_import($localPath);
	}
    }
    return 1;
}


#
# Private Methods
#

sub _import {
    my $self   = shift;
    my $path   = shift;
    my $store  = $self->{STORE};

    $self->verbose(1, "For store \"$store\"\n");
    $self->verbose(1, "Import GoldCard from \"$path\"\n");
    $self->verbose(1, "Using database \"", $self->database->name, "\"\n");

    my $dbh = GSI::DBI::Connection->connect($self->database->name,
					    { RaiseError => 1,
					      AutoCommit => 0,
					    });
    my $mySYSDATE = strftime("%m/%d/%Y %H:%M", localtime(time-172800));
    $self->verbose(1, "Batch timestamp = $mySYSDATE\n");

    # These are in GoldCard.pm; they are shared between Import, Export, etc.
    my $mlpId		= $self->{MLP_PROGRAM_ID};
    my @mlpCols		= @{$self->{MLP_COLS}};
    my @gncCols		= @{$self->{GNC_COLS}};
    my @attribCols	= (qw/PROGRAM_ID ACCOUNT_ID REPL_TYPE/);

    # Use this map to catch database errors for reporting records that
    # fail to update.
    my $errorMap = $self->_errorMap();

    # Use this SQL to check for existing GoldCard accounts.
    my $existingSQL = $self->_existingSQL($store);

    # Use this SQL to add records to the mlp_account_feeds staging table.
    my $insertSQL = $self->_insertSQL($mySYSDATE);

    # Use this SQL template for inserting records to the mlp_account_attrib_feeds
    # table.
    my $insAttribSQL = $self->_insertAttribSQL();

    # Use this SQL template to determine the REPL_TYPE for records inserted
    # into the mlp_account_attrib_feeds table according to whether the attrib
    # already exists (which is only possible when the corresponding
    # mlp_account_feeds record is an "ADD" (repl_type 1)
    my $curAttribSQL = $self->_existingAttribSQL();

    # Use this anonymous subroutine to modify the "cur" SQL with the
    # account_id, since TableChange doesn't support bind parameters.
    my $accountSub = sub {
	my $sql = shift;
	my $id  = shift;
	$sql .= " AND account_id = '$id'";
	return $sql;
    };

    # Use this anonymous subroutine to modify the attrib_tag in the above
    # two attrib sql statements on-the-fly.
    my $attribSub = sub {
	my $sql	    = shift;
	my $tag	    = shift;
	my $sysdate = shift;
	$sql =~ s/TTTTTTTTTT/$tag/g;
	$sql =~ s/SSSSSSSSSS/$sysdate/g if (defined $sysdate);
	return $sql;
    };

    my ($inAccts, $addAccts, $chgAccts) = (0, 0, 0);
    my %addAttribs = ();
    my %chgAttribs = ();
    my $commonMap = [
	   CountRows	=> { COUNTER	=> \$inAccts, }
	=> Debug	=> { MESSAGE	=> ">>> Delimited Input ",
			     USE	=> $verboseLevel > 4,
			   }

	# Rename the columns from the GNC input file to match our database.
	# Attaching GNC's column names on input eases debugging.
	=> CopyCols	=> { MAP	=> {
		GNC_GOLD_CARD_NBR			=> 'ACCOUNT_ID',
		GSI_BILL_TO_NBR				=> 'USER_ID',
		BIRTH_MONTH				=> 'b_month',
		BIRTH_YEAR				=> 'b_year',
		CITY					=> 'CITY',
		COUNTRY					=> 'COUNTRY_CODE',
		CUSTOMER_PREF_BONE_JOINT_HEALTH		=> 'p_bone',
		CUSTOMER_PREF_FITNESS_STRENGTH		=> 'p_fitness',
		CUSTOMER_PREF_HEART_HEALTH		=> 'p_heart',
		CUSTOMER_PREF_NATURAL_REMEDIES		=> 'p_natural',
		CUSTOMER_PREF_VITAMINS			=> 'p_vitamins',
		CUSTOMER_PREF_WEIGHT_LOSS_LOW_CARB	=> 'p_weight',
		DO_NOT_MAIL_FLAG			=> 'dn_mail',
		DO_NOT_RENT_FLAG			=> 'dn_rent',
		DO_NOT_TELEMARKET_FLAG			=> 'dn_tele',
		EMAIL_ADDRESS				=> 'EMAIL',
		EMAIL_OPTIN_FLAG			=> 'EMAIL_PREFERENCE',
		FIRST_NAME				=> 'FIRST_NAME',
		GENDER					=> 'GCGENDER',
		LAST_NAME				=> 'LAST_NAME',
		MAGAZINE_PREFERENCE			=> 'GCMAGPREFS',
		MIDDLE_INITIAL				=> 'GCMIDDLEINITIAL',
		PHONE_NUMBER_AREA_CODE			=> 't_acode',
		PHONE_NUMBER_PREFIX			=> 't_prefix',
		PHONE_NUMBER_SUFFIX			=> 't_suffix',
		STATE					=> 'STATE_CODE',
		STREET_ADDRESS				=> 'ADDRESS1',
		ZIP_CODE				=> 'z_code',
		ZIP_EXTENSION				=> 'z_extension',
		GSI_RECORD_MODIFIED_DATE		=> 'gsi_mod_dt',
		GSI_REASON_CARD_PURCHASED_RENEWED_OR_UPDATED  => 'gsi_reason',
		GSI_SHIPPED_DATE_4_CARD_PURCHASED_OR_RENEWED  => 'gsi_ship_dt',
		GSI_GNC_GOLD_CARD_EXPIRATION_DATE	=> 'EXPIRY_DATE',
					   },
			   }
	=> TextMunge	=> { COLUMN	=> 'z_code',
			     REGEXP	=> q#s/^(\d{5}).*$/$1/#,
			     USE	=> 0,
			   }
	=> TextMunge	=> { COLUMN	=> 'z_extension',
			     REGEXP	=> q#s/^(\d{4}).*$/$1/#,
			     USE	=> 0,
			   }
	=> RowAdd	=> { VALUES	=> {
		STORE_CODE	=> $store,
		PROGRAM_ID	=> $mlpId,
		PHONE_DAY	=> '${t_acode}${t_prefix}${t_suffix}',
		GCDATEOFBIRTH	=> '${b_month}/00/${b_year}',
		POSTAL_CODE	=> '${z_code}${z_extension}',
		COUNTRY_CODE	=> 'US',
		DATE_ADDED	=> $mySYSDATE,
		DATE_MODIFIED	=> $mySYSDATE,
					   },
			   }
	=> TextExpand	=> { COLUMNS	=> [qw/PHONE_DAY
					       GCDATEOFBIRTH
					       POSTAL_CODE/],
			   }
	=> TextMunge	=> { COLUMN	=> 'POSTAL_CODE',
			     REGEXP	=> q#s/\s//g#,
			   }
	=> Debug	=> { MESSAGE	=> ">>> Common Map Output ",
			     USE	=> $verboseLevel > 4,
			   }

	### Map must end with Continue else preceeding Debug is treated
	### as an output and the additions/changes to this row are not
	### seen in the main map.
	=> Continue	=> { }

    ];

    # NOTE - Nothing done on import for GCEmailPrefs.
    # The three "dn_" / "DO_NOT" flags are not saved from the inbound feed,
    # but are manufactured from EMAIL_PREFERENCE on output according to
    # an algorithm from GNC.  Refer to Export.pm for details.


    # The CHANGE_FLAG from TableChange is:
    # A - Add:	      input record not in database
    # C - Change:     input record differs from database
    # D - Delete:     database record not in master file
    # N - No change:  identical records
    #
    # For this feed:
    # A => add a new GoldCard account
    # C => change an existing GoldCard account
    # D => ignore
    # N => ignore

    my @maps = ();	# 6 total: 1 for mlp_account, 5 for mlp_account_attrib.

    # MLP_ACCOUNT_FEEDS
    $maps[0] = [
	   Delimited	=> { FILE_NAME	=> $path,
			     COLUMNS	=> \@gncCols,
			   }
	=> $commonMap
	=> Debug	=> { MESSAGE	=> ">>> After Common Map ",
			     USE	=> $verboseLevel > 4,
			   }

	=> TableChange	=> { DATABASE		=> $self->database,
			     SQL		=> $existingSQL,
			     INDEX		=> 'ACCOUNT_ID',
			     CHANGE_COL		=> 'CHANGE_FLAG',
			     WANTED		=> [qw/A C/],
			     COLUMN_CASE	=> 'UPPER',
			     PRE_FETCH		=> 0,
			     ROW_ARG		=> 'ACCOUNT_ID',
			   }
	=> Debug	=> { MESSAGE	=> ">>> Account Map ",
			     USE	=> $verboseLevel > 4,
			   }

### For testing, terminate the map here to short-circuit DBTable below.
###	=> Break	=> { }

#...testing:  how to get rid of redundant DBTables in these submaps and use
# one at the end...
	# ADD...
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'A',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '1', }, }
	   => CountRows	=> { COUNTER	=> \$addAccts, }
#ng see DBTable note below...
#	   => Continue	=> { }
	   => Debug	=> { MESSAGE => ">>> Account DBTable Input - ADD ",
			     USE     => $verboseLevel > 4,
			   }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> $insertSQL,
			     ROW_ARG	=> \@mlpCols,
			     ERROR_MAP	=> $errorMap,
			   }
	   ]

	# CHANGE...
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'C',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '2', }, }
	   => CountRows	=> { COUNTER	=> \$chgAccts, }
#ng see DBTable note below...
#	   => Continue	=> { }
	   => Debug	=> { MESSAGE => ">>> Account DBTable Input - CHANGE ",
			     USE     => $verboseLevel > 4,
			   }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> $insertSQL,
			     ROW_ARG	=> \@mlpCols,
			     ERROR_MAP	=> $errorMap,
			   }
	   ]

# Want DBTable here, only once; can't figure out how to get REPL_TYPE
# to come out of above ADD/CHANGE maps to be non-NULL at this point...
# Shouldn't the "Continues" above, when used instead of the DBTables above,
# pass the row out of the submaps?
#	   => Debug	=> { MESSAGE => ">>> Account DBTable Input ",
#			     USE     => $verboseLevel > 4,
#			   }
#	=> DBTable	=> { DBH	=> $dbh,
#			     COMMIT	=> 1000,
#			     SQL	=> $insertSQL,
#			     ROW_ARG	=> \@mlpCols,
#			     ERROR_MAP	=> $errorMap,
#			   }
    ];	 # end of MLP_ACCOUNT_FEEDS


    # MLP_ACCOUNT_ATTRIB_FEEDS - GCDateOfBirth
    $maps[1] = [
	   Delimited	=> { FILE_NAME	=> $path,
			     COLUMNS	=> \@gncCols,
			   }
	=> $commonMap
	=> Debug	=> { MESSAGE	=> ">>> After Common Map ",
			     USE	=> $verboseLevel > 4,
			   }

	=> TextMunge	=> { COLUMN	=> 'GCDATEOFBIRTH',
			     REGEXP	=> q#s/^\s*\/00\/\s*$/ /#,
# this too for empty month?	[ ..., q#s/^(\/00\/[12][0-9]{3})$/00$1#, ]
			   }
	=> TableChange	=> { DATABASE		=> $self->database,
			     SQL		=> eval {
				$attribSub->($curAttribSQL, 'GCDateOfBirth');
							},
			     INDEX		=> 'ACCOUNT_ID',
			     CHANGE_COL		=> 'CHANGE_FLAG',
			     WANTED		=> [qw/A C/],
			     COLUMN_CASE	=> 'UPPER',
			     PRE_FETCH		=> 0,
			     ROW_ARG		=> 'ACCOUNT_ID',
			   }
	=> Debug	=> { MESSAGE => ">>> GCDateOfBirth Map ",
			     USE     => $verboseLevel > 4,
			   }

	# ADD... but only if not empty.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'A',
				   }
	   => ColumnMatch	=> { COLUMN	=> 'GCDATEOFBIRTH',
				     MATCH	=> qr/\S+/,
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '1', }, }
	   => CountRows	=> { COUNTER	=> \$addAttribs{GCDateOfBirth}, }
	   => Debug	=> { MESSAGE => ">>> GCDateOfBirth DBTable Input ",
			     USE     => $verboseLevel > 4,
			   }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCDateOfBirth', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCDATEOFBIRTH'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]

	# CHANGE... always.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'C',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '2', }, }
	   => CountRows	=> { COUNTER	=> \$chgAttribs{GCDateOfBirth}, }

	   => Debug	=> { MESSAGE => ">>> GCDateOfBirth DBTable Input ",
			     USE     => $verboseLevel > 4,
			   }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCDateOfBirth', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCDATEOFBIRTH'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]
    ];	# end of MLP_ACCOUNT_ATTRIB_FEEDS - GCDateOfBirth


    # MLP_ACCOUNT_ATTRIB_FEEDS - GCGender
    $maps[2] = [
	   Delimited	=> { FILE_NAME	=> $path,
			     COLUMNS	=> \@gncCols,
			   }
	=> $commonMap
	=> Debug	=> { MESSAGE	=> ">>> After Common Map ",
			     USE	=> $verboseLevel > 4,
			   }

	=> TextMunge	=> { COLUMN	=> [qw/GCGENDER/],
			     REGEXP	=> q#s/^\s*$/ /#,
			     UNDEF_OK	=> 1,
			   }
	=> TextMunge	=> { COLUMN	=> [qw/GCGENDER/],
			     REGEXP	=> q#s/^\s*$/ /#,
			     UNDEF_OK	=> 1,
			   }
	=> TableChange	=> { DATABASE		=> $self->database,
			     SQL		=> eval {
				$attribSub->($curAttribSQL, 'GCGender');
							},
			     INDEX		=> 'ACCOUNT_ID',
			     CHANGE_COL		=> 'CHANGE_FLAG',
			     WANTED		=> [qw/A C/],
			     COLUMN_CASE	=> 'UPPER',
			     PRE_FETCH		=> 0,
			     ROW_ARG		=> 'ACCOUNT_ID',
			   }
	=> Debug	=> { MESSAGE	=> ">>> GCGender Map ",
			     USE	=> $verboseLevel > 4,
			   }

	# ADD... but only if not empty.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'A',
				   }
	   => ColumnMatch	=> { COLUMN	=> 'GCGENDER',
				     MATCH	=> qr/\S+/,
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '1', }, }
	   => CountRows	=> { COUNTER	=> \$addAttribs{GCGender}, }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCGender', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCGENDER'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]

	# CHANGE... always.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'C',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '2', }, }
	   => CountRows	=> { COUNTER	=> \$chgAttribs{GCGender}, }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCGender', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCGENDER'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]
    ];	# end of MLP_ACCOUNT_ATTRIB_FEEDS - GCGender


    # MLP_ACCOUNT_ATTRIB_FEEDS - GCInterestCats (aka Customer Preferences aka
    # Interest Categories).  Convert these Y/space preference flags to the
    # preference name for storage in the mlp attribute "GCInterestCats"
    $maps[3] = [
	   Delimited	=> { FILE_NAME	=> $path,
			     COLUMNS	=> \@gncCols,
			   }
	=> $commonMap
	=> Debug	=> { MESSAGE	=> ">>> After Common Map ",
			     USE	=> $verboseLevel > 4,
			   }

	=> TextMunge	=> { COLUMN	=> 'p_bone',
			     REGEXP	=> [
				q#s/Y/customer_pref_bone_joint_health/g#,
				q#s/\s*//g#],
			   }
	=> TextMunge	=> { COLUMN	=> 'p_fitness',
			     REGEXP	=> [
				q#s/Y/customer_pref_fitness_strength/g#,
				q#s/\s*//g#],
			   }
	=> TextMunge	=> { COLUMN	=> 'p_heart',
			     REGEXP	=> [
				q#s/Y/customer_pref_heart_health/g#,
				q#s/\s*//g#],
			   }
	=> TextMunge	=> { COLUMN	=> 'p_natural',
			     REGEXP	=> [
				q#s/Y/customer_pref_natural_remedies/g#,
				q#s/\s*//g#],
			   }
	=> TextMunge	=> { COLUMN	=> 'p_vitamins',
			     REGEXP	=> [
				q#s/Y/customer_pref_vitamins/g#,
				q#s/\s*//g#],
			   }
	=> TextMunge	=> { COLUMN	=> 'p_weight',
			     REGEXP	=> [
				q#s/Y/customer_pref_weight_loss_low_carb/g#,
				q#s/\s*//g#],
			   }
	=> JoinCols	=> { COLUMNS	=> [qw/p_bone p_fitness p_heart p_natural
					       p_vitamins p_weight/],
			     DELIMITER	=> '|',
			     TARGET_COL	=> 'GCINTERESTCATS',
			   }
	=> TextMunge	=> { COLUMN	=> 'GCINTERESTCATS',
			     REGEXP	=> [q#s/^\|+$/ /#,
					    q#s/^\|+//#,
					    q#s/\|+$//#,
					    q#s/\|{2,}/|/g#],
			   }
	=> TextMunge	=> { COLUMN	=> [qw/GCINTERESTCATS/],
			     REGEXP	=> q#s/^\s*$/ /#,
			     UNDEF_OK	=> 1,
			   }
	=> TableChange	=> { DATABASE		=> $self->database,
			     SQL		=> eval {
				$attribSub->($curAttribSQL, 'GCInterestCats');
							},
			     INDEX		=> 'ACCOUNT_ID',
			     CHANGE_COL		=> 'CHANGE_FLAG',
			     WANTED		=> [qw/A C/],
			     COLUMN_CASE	=> 'UPPER',
			     PRE_FETCH		=> 0,
			     ROW_ARG		=> 'ACCOUNT_ID',
			   }
	=> Debug	=> { MESSAGE	=> ">>> GCInterestCats Map ",
			     USE	=> $verboseLevel > 4,
			   }

	# ADD... but only if not empty.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'A',
				   }
	   => ColumnMatch	=> { COLUMN	=> 'GCINTERESTCATS',
				     MATCH	=> qr/\S+/,
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '1', }, }
	   => CountRows	=> { COUNTER	=> \$addAttribs{GCInterestCats},}
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCInterestCats', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCINTERESTCATS'],
			     ERROR_MAP	=> $errorMap,
			   }

	   ]

	# CHANGE... always.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'C',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '2', }, }
	   => CountRows	=> { COUNTER	=> \$chgAttribs{GCInterestCats},}
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCInterestCats', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCINTERESTCATS'],
			     ERROR_MAP	=> $errorMap,
			   }

	   ]
    ];	# end of MLP_ACCOUNT_ATTRIB_FEEDS - GCInterestCats


    # MLP_ACCOUNT_ATTRIB_FEEDS - GCMagPrefs
    $maps[4] = [
	   Delimited	=> { FILE_NAME	=> $path,
			     COLUMNS	=> \@gncCols,
			   }
	=> $commonMap
	=> Debug	=> { MESSAGE	=> ">>> After Common Map ",
			     USE	=> $verboseLevel > 4,
			   }

	=> TextMunge	=> { COLUMN	=> [qw/GCMAGPREFS/],
			     REGEXP	=> q#s/^\s*$/ /#,
			     UNDEF_OK	=> 1,
			   }
	=> TableChange	=> { DATABASE		=> $self->database,
			     SQL		=> eval {
				$attribSub->($curAttribSQL, 'GCMagPrefs');
							},
			     INDEX		=> 'ACCOUNT_ID',
			     CHANGE_COL		=> 'CHANGE_FLAG',
			     WANTED		=> [qw/A C/],
			     COLUMN_CASE	=> 'UPPER',
			     PRE_FETCH		=> 0,
			     ROW_ARG		=> 'ACCOUNT_ID',
			   }
	=> Debug	=> { MESSAGE	=> ">>> GCMagPrefs Map ",
			     USE	=> $verboseLevel > 4,
			   }

	# ADD... but only if not empty.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'A',
				   }
	   => ColumnMatch	=> { COLUMN	=> 'GCMAGPREFS',
				     MATCH	=> qr/\S+/,
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '1', }, }
	   => CountRows	=> { COUNTER	=> \$addAttribs{GCMagPrefs}, }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCMagPrefs', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCMAGPREFS'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]

	# CHANGE... always.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'C',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '2', },  }
	   => CountRows	=> { COUNTER	=> \$chgAttribs{GCMagPrefs}, }
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCMagPrefs', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCMAGPREFS'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]
    ];	# end of MLP_ACCOUNT_ATTRIB_FEEDS - GCMagPrefs

    # MLP_ACCOUNT_ATTRIB_FEEDS - GCMiddleInitial
    $maps[5] = [
	   Delimited	=> { FILE_NAME	=> $path,
			     COLUMNS	=> \@gncCols,
			   }
	=> $commonMap
	=> Debug	=> { MESSAGE	=> ">>> After Common Map ",
			     USE	=> $verboseLevel > 4,
			   }

	=> TextMunge	=> { COLUMN	=> [qw/GCMIDDLEINITIAL/],
			     REGEXP	=> q#s/^\s*$/ /#,
			     UNDEF_OK	=> 1,
			   }
	=> TableChange	=> { DATABASE		=> $self->database,
			     SQL		=> eval {
				$attribSub->($curAttribSQL, 'GCMiddleInitial');
							},
			     INDEX		=> 'ACCOUNT_ID',
			     CHANGE_COL		=> 'CHANGE_FLAG',
			     WANTED		=> [qw/A C/],
			     COLUMN_CASE	=> 'UPPER',
			     PRE_FETCH		=> 0,
			     ROW_ARG		=> 'ACCOUNT_ID',
			   }
	=> Debug	=> { MESSAGE	=> ">>> GCMiddleInitial Map ",
			     USE	=> $verboseLevel > 4,
			   }

	# ADD... but only if not empty.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'A',
				   }
	   => ColumnMatch	=> { COLUMN	=> 'GCMIDDLEINITIAL',
				     MATCH	=> qr/\S+/,
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '1', }, }
	   => CountRows	=> { COUNTER	=> \$addAttribs{GCMiddleInitial}}
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCMiddleInitial', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCMIDDLEINITIAL'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]

	# CHANGE... always.
	=> [  ColumnMatch	=> { COLUMN	=> 'CHANGE_FLAG',
				     MATCH	=> 'C',
				   }
	   => RowAdd	=> { VALUES	=> { REPL_TYPE => '2', }, }
	   => CountRows	=> { COUNTER	=> \$chgAttribs{GCMiddleInitial}}
	   => DBTable	=> { DBH	=> $dbh,
			     COMMIT	=> 1000,
			     SQL	=> eval {
		$attribSub->($insAttribSQL, 'GCMiddleInitial', $mySYSDATE);
						},
			     ROW_ARG	=> [@attribCols, 'GCMIDDLEINITIAL'],
			     ERROR_MAP	=> $errorMap,
			   }
	   ]
    ];	# end of MLP_ACCOUNT_ATTRIB_FEEDS - GCMiddleInitial

    translate($maps[$self->{WHICH_IMPORT_STEP}]);

    my $totalAccts = $addAccts + $chgAccts;
    $self->verbose(1, "\n$store Gold Card master file has $inAccts records\n");
    if ($totalAccts > 0) {
	$self->verbose(1, "\nMLP accounts loaded:  $addAccts add +",
		       " $chgAccts change = $totalAccts total\n");
    }

    my $totalAttribs = 0;
    $self->verbose(1, "MLP Account Attributes loaded:\n");
    foreach my $attrib (sort keys %addAttribs) {
	my $add = $addAttribs{$attrib} ? $addAttribs{$attrib} : 0;
	my $chg = $chgAttribs{$attrib} ? $chgAttribs{$attrib} : 0;
	my $tot = $add + $chg;
	if ($tot > 0) {
	    $attrib .= ':';
	    my $s = $attrib . ' ' x (20 - length($attrib));
	    $self->verbose(1,
			   sprintf("\t%20s %7d add + %7d change = %9d total\n",
				   $s, $add, $chg, $tot));
	    $totalAttribs += $tot;
	}
    }
    $self->verbose(1, "Total MLP Account Attributes loaded:  $totalAttribs\n");
    $self->verbose(1, "Total records loaded into ", $self->database->name,
		   " DB:  ", $totalAccts + $totalAttribs, "\n\n");

    $self->{INPUT_COUNT}  = $inAccts;
    $self->{ADD_COUNT}    = $addAccts;
    $self->{CHANGE_COUNT} = $chgAccts;
    $self->{TOTAL_COUNT}  = $totalAccts;
}



sub _errorMap() {
    my $self = shift;
    my @gncCols	= @{$self->{GNC_COLS}};
    my $opts = {};

    my $reportSet = GSI::DataX::GNC::GoldCard::Files::ErrorReport->new($opts);
    my $reportName = $reportSet->{SET_NAME};
    my $reportPath = $reportSet->new_file->path;

    my $errorMap = [
	   Null		=> {}
	=> NewlineRemove=> { COLUMNS	=> [qw/OUTPUT_ERROR/], }
	=> Debug	=> { MESSAGE	=> ">>> Error Report ",
			   }
##	=> TextMunge	=> { COLUMN	=> 'OUTPUT_ERROR',
###old, but ng...		     REGEXP	=> q#s/\n\r\t/ /g#,
###new, ng?
##			     REGEXP	=> q#s/[\n\r\t]/ /g#,
###new?			     REGEXP	=> q#s/^([^\n\r\t]*)([\n\r\t])$/ /g#,
##			     USE	=> 0,
##			   }
	=> Delimited	=> { FILE	=>
#					$reportSet,
					$reportPath,
#		"$ENG_REPORT_DIR/GNC_GoldCard_Error_YYYYMMDDHHHHMMSS.txt",
#			     COLUMNS	=> [@gncCols, 'ERROR_MESSAGE'],
			     COLUMNS	=> [@gncCols, 'OUTPUT_ERROR'],
			     SHOW_ERROR	=> 0,
			   }
    ];
    return $errorMap;
}


# Use this SQL to check the mlp_account table for existing GoldCard accounts.
sub _existingSQL {
    my $self  = shift;
    my $mlpId = $self->{MLP_PROGRAM_ID};
    my $legacy = $self->{LEGACY_FLAG};

    my $existingSQL = <<"END_EXISTING_SQL";
    SELECT	account_id, date_added, date_modified
--ok?    SELECT	account_id
    FROM	mlp_account
    WHERE	program_id = $mlpId AND account_id = ?
END_EXISTING_SQL

    $existingSQL =~ s/$/ and rownum < 1/ if ($legacy);
    $self->verbose(2, "existingSQL =\n$existingSQL\n");
    return $existingSQL;
}


# Use this SQL to add records to the mlp_account_feeds staging table.
sub _insertSQL {
    my $self = shift;
    my $sysdate = shift;
    my $mlpColList = join(", ", @{$self->{MLP_COLS}});
    my $legacy = $self->{LEGACY_FLAG};

    my $insertSQL = <<"END_INSERT_SQL";
    INSERT INTO mlp_account_feeds (
	$mlpColList,
	TIMESTAMP
    )
    VALUES (
	?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
	TO_DATE(?, 'MM/DD/YYYY'),
	TO_DATE(?, 'MM/DD/YYYY HH24:MI'),
	TO_DATE(?, 'MM/DD/YYYY HH24:MI'),
	TO_DATE('$sysdate', 'MM/DD/YYYY HH24:MI')
    )
END_INSERT_SQL

    $insertSQL =~ s/(mlp_account_feeds)/legacy_$1/ if ($legacy);
    $self->verbose(2, "insertSQL =\n$insertSQL\n");
    return $insertSQL;
}


# Use this SQL to check the mlp_account_attrib table for existing attribs.
sub _existingAttribSQL {
    my $self	  = shift;
    my $attribTag = shift;
    my $mlpId = $self->{MLP_PROGRAM_ID};
    my $legacy = $self->{LEGACY_FLAG};

    # TTTTTTTTTT replaced later with the true tag name, e.g. `CGGender'
    my $existingAttribSQL = <<"END_EXISTING_ATTRIB_SQL";
    SELECT	account_id, attrib_text TTTTTTTTTT
    FROM	mlp_account_attrib
    WHERE	    program_id = $mlpId AND account_id = ?
		AND attrib_tag = 'TTTTTTTTTT'
END_EXISTING_ATTRIB_SQL

    $existingAttribSQL =~ s/$/ and rownum < 1/ if ($legacy);
    $self->verbose(2, "existingAttribSQL =\n$existingAttribSQL\n");
    return $existingAttribSQL;
}

# Use this SQL to add records to the mlp_account_attrib_feeds staging table.
sub _insertAttribSQL {
    my $self = shift;
    my $legacy = $self->{LEGACY_FLAG};

    # TTTTTTTTTT replaced later with the true tag name, e.g. `CGGender'
    my $insertAttribSQL = <<"END_INSERT_ATTRIB_SQL";
    INSERT INTO mlp_account_attrib_feeds (
	PROGRAM_ID, ACCOUNT_ID, REPL_TYPE, ATTRIB_TAG, ATTRIB_TEXT,
	ATTRIB_VALUE, TIMESTAMP
    )
    VALUES (
	?, ?, ?, 'TTTTTTTTTT', ?,
	0, TO_DATE('SSSSSSSSSS', 'MM/DD/YYYY HH24:MI')
    )
END_INSERT_ATTRIB_SQL

    $insertAttribSQL =~ s/(mlp_account_attrib_feed)s/legacy_$1/ if ($legacy);
    $self->verbose(2, "insertAttribSQL =\n$insertAttribSQL\n");
    return $insertAttribSQL;
}


1;
