#
# GNC Gold Card Loyalty Program.
#

#
# $Id: GoldCard.pm,v 1.35 2007/01/22 18:34:45 donohuet Exp $
#

#
# 1. GNC sends initial ~9M records to GSI:
#    a. sql load into db by dba's
# 2. GSI sends daily customer record updates to GNC, e.g.:
#    $ datax -extract -zip -upload gnc.goldcard
#    a. change of address
#    b. gold card info, e.g.:
#       i.  gc number on purchase
#       ii. expire date on renewal
#    c. preferences, e.g.:
#       i.  email
#       ii. telemarketing
# 3. GNC sends weekly customer record updates to GSI:
#    $ datax -download -unzip -validate -import gnc.goldcard
#


use strict;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataX::GNC::Base;
our @ISA = qw(GSI::DataX::GNC::Base);

use GSI::DataX::GNC::GoldCard::Utils;
use GSI::Utils::Timing;

use GSI::OptArg::ClassAttr {
    DATABASE	=> { MODIFY         => 1,
		     ALIASES        => [qw/EXISTING_DB MASTER_DB/],
		     DEFAULT        => 'Developer',
# GNC QA	     DEFAULT        => 'Staging2',	#
# GNC PROD export    DEFAULT        => 'History,	#
# GNC LEGACY import  DEFAULT        => 'feedsprd',	#
# GNC PREPROD import DEFAULT        => 'feedstrans1b',	# aka "feeds@trans1b"
# GNC PROD import    DEFAULT        => 'ProdFeeds',	# aka "feeds@trans1a"
		   },

    # To use or not to use the database.  That is the question.
    USE_DB	=> { TYPE	=> 'BOOL',
		     DEFAULT	=> 1,
		   },

    # Program Id of the GNC Gold Card Membership Loyalty Program.
    MLP_PROGRAM_ID => { TYPE	=> 'SCALAR',
			DEFAULT	=> '2150040',
		      },

    # List of Account Ids, mlp_account.account_id constraint for debugging.
    ACCOUNT_IDS	=> { TYPE	=> 'ARRAY',
		     DEFAULT	=> undef,
		   },

    # List of User Ids, customer.user_id constraint for debugging.
    USER_IDS	=> { TYPE	=> 'ARRAY',
		     DEFAULT	=> undef,
		   },

    STORE	=> { TYPE	=> 'SCALAR',
		     DEFAULT	=> qw/GNC/,
		   },

    USE_QUERY   => { TYPE       => 'SCALAR',
                     DEFAULT    => 0,
                   },

    # Due to linux 4G process adderss space constraint, import must work on
    # the input file in multiple steps to fully load it:  1 for mlp_account,
    # 5 for the mlp_account_attribs.
    #
    # Step	Action
    # ----	---------------
    # 0		Account
    # 1		GCDateOfBirth
    # 2		GCGender
    # 3		GCInterestCats
    # 4		GCMagPrefs
    # 5		GCMiddleInitial
    #
    WHICH_IMPORT_STEP	=> { TYPE	=> 'SCALAR',
			     DEFAULT	=> 0,
			   },
    IMPORT_STEPS	=> { TYPE	=> 'ARRAY',
			     DEFAULT	=> [qw/Account
					       GCDateOfBirth
					       GCGender
					       GCInterestCats
					       GCMagPrefs
					       GCMiddleInitial/],
			   },

    # On the command line use -mailto=abc,xyz, not -mailto='abc xyz'
    MAIL_TO	=> { TYPE	=> 'ARRAY',
#todo		     DEFAULT	=> [qw/gncmarketing@gnc-hq.com/],
		     DEFAULT	=> [qw/donohuet@gsicommerce.com/],
		   },

    MAIL_FEEDS	=> { TYPE	=> 'ARRAY',
		     DEFAULT	=> [qw/feedsnotify@gsicommerce.com/],
		   },

    MAIL_FROM	=> { TYPE	=> 'SCALAR',
		     DEFAULT	=> 'feedsnotify@gsicommerce.com',
		   },

    MAIL_IMPORT_SUBJECT	=> { TYPE	=> 'SCALAR',
			     DEFAULT	=> q(GNC Weekly Customer File - DWWP0832),
			   },

    MAIL_IMPORT_BODY	=> { TYPE	=> 'SCALAR',
			     DEFAULT	=> q(
GSI failed to receive and/or process the weekly customer data exchange file created by job DWWP0832.  On call person, assure DWWP0832 finished properly and that our FTP server delivered the file.  Call GSI (Bill Locke - 610.491.7246) to determine why GSI did not process.  Retransmission of this week's file will most likely be required.),
			   },

    MAIL_EXPORT_SUBJECT	=> { TYPE	=> 'SCALAR',
			     DEFAULT	=>
			     q(Warning - GNC Daily Customer File Not Found),
			   },

    MAIL_EXPORT_BODY	=> { TYPE	=> 'SCALAR',
			     DEFAULT	=> q(
The daily GNC Customer file normally created on secprdfdsapp01 by feeds cronjob "datax -export gnc.goldcard" cannot be found in /feeds/data/gnc/gold_card/export.  Please investigate.),
			   },


    MAIL_TO_FEEDS	=> { TYPE	=> 'ARRAY',
#todo			     DEFAULT	=> [qw/feedsnotify@gsicommerce.com/],
			     DEFAULT	=> [qw/donohuet@gsicommerce.com/],
			   },

    MAIL_BODY_FEEDS	=> { TYPE	=> 'SCALAR',
			     DEFAULT	=> qq(
OBM & Production Support:

The following alert was sent to GNC for investigation.  Take no action until GNC contacts us.  GNC may request that the Gold Card datafeed be run again or that GSI investigate the file exchange:  please ask the datafeeds team to assist.\n\n),
			   },

    # MAIL_SIGs are not presently used...  Originally tried embedding "$mailFrom"
    # in a single MAIL_SIG string and using eval to expand it at run-time, but
    # couldn't get that to work...
    MAIL_SIG1	=> { TYPE	=> 'SCALAR',
		     DEFAULT	=> q(
Please direct inquiries about this report to the DataFeeds Team at GSI Commerce.

--),
		   },

    MAIL_SIG2	=> { TYPE	=> 'SCALAR',
		     DEFAULT	=> q(
GSI Commerce, Inc.
http://www.gsicommerce.com

The information contained in this electronic mail transmission is intended only for the use of the individual or entity named in this transmission. If you are not the intended recipient of this transmission, you are hereby notified that any disclosure, copying or distribution of the contents of this transmission is strictly prohibited and that you should delete the contents of this transmission from your system immediately. Any comments or statements contained in this transmission do not necessarily reflect the views or position of GSI Commerce, Inc. or its subsidiaries and/or affiliates.),
		   },


    'GSI::File::Set' => [qw/LS_MODE/],

    # Local input file name, for use from the commandline.
    INPUT_FILE	=> { TYPE	=> 'SCALAR', Default	=> undef },

    # Legacy flag, to control the table names for initial vs. on-going loads.
    LEGACY_FLAG	=> { TYPE	=> 'SCALAR', Default	=> 0 },

    ACTIONS	=> { MODIFY	=> 1,
		     DEFAULT	=> [qw/Files
				       Download Unzipit Validate Import
				       Export Gather Zipit Upload
				       Report Send
				       CheckImport CheckExport/],
		   },

    REMOTE	=> { TYPE	=> 'BOOL' },
    LOCAL	=> { TYPE	=> 'BOOL' },
    REPORT	=> { TYPE	=> 'BOOL' },

    # In production, run with "-start=yesterday -end=yesterday"
    # but don't make that the default here!
    DATES	=> { TYPE	=> 'DateRange',	MODIFY	   => 1,
		     METHOD_GET	=> 'public',    METHOD_SET => 'public',
		     DIRECT_GET	=> 'protected', DIRECT_SET => 'private',
		     ALIASES	=> [qw/DATE DATE_RANGE/],
#		     DEFAULT	=> { START => 'today', END => 'today', },
#		     DEFAULT	=> { START => 'yesterday', END => 'yesterday', },
		     DEFAULT	=> { START => 'yesterday', END => 'today', },
		     DEPENDENCIES => [qw/ACTIONS/],
		   },

    # Sanity check file received from GNC
#    HEADER		=> { TYPE => 'BOOL',	DEFAULT => 1 },
    MIN_ROW_COUNT	=> { TYPE => 'SCALAR',	DEFAULT => 10 },	#todo

    ##
    ## These won't really ever be set from the command line, they are
    ## here because they are shared by the datax action objects.
    ##

    # Column names in the GNC GoldCard feed:  input and output file
    # formats are identical, and the header does not appear in the files.
    GNC_COLS	=> { TYPE	=> 'ARRAY',
		     DEFAULT	=> [
		     qw/GNC_GOLD_CARD_NBR
			GSI_BILL_TO_NBR
			BIRTH_MONTH
			BIRTH_YEAR
			CITY
			COUNTRY
			CUSTOMER_PREF_BONE_JOINT_HEALTH
			CUSTOMER_PREF_FITNESS_STRENGTH
			CUSTOMER_PREF_HEART_HEALTH
			CUSTOMER_PREF_NATURAL_REMEDIES
			CUSTOMER_PREF_VITAMINS
			CUSTOMER_PREF_WEIGHT_LOSS_LOW_CARB
			DO_NOT_MAIL_FLAG
			DO_NOT_RENT_FLAG
			DO_NOT_TELEMARKET_FLAG
			EMAIL_ADDRESS
			EMAIL_OPTIN_FLAG
			FIRST_NAME
			GENDER
			LAST_NAME
			MAGAZINE_PREFERENCE
			MIDDLE_INITIAL
			PHONE_NUMBER_AREA_CODE
			PHONE_NUMBER_PREFIX
			PHONE_NUMBER_SUFFIX
			STATE
			STREET_ADDRESS
			ZIP_CODE
			ZIP_EXTENSION
			GSI_RECORD_MODIFIED_DATE
			GSI_REASON_CARD_PURCHASED_RENEWED_OR_UPDATED
			GSI_SHIPPED_DATE_4_CARD_PURCHASED_OR_RENEWED
			GSI_GNC_GOLD_CARD_EXPIRATION_DATE/],
		   },

    # These column names are in the mlp_account table.  For most the values
    # are directly copied from the GNC feed, but:
    # a) PROGRAM_ID is set by the feed
    # b) PHONE_NUMBER is a composite of:
    #	  PHONE_NUMBER_AREA_CODE, PHONE_NUMBER_PREFIX, PHONE_NUMBER_SUFFIX
    # c) POSTAL_CODE is a composite of:
    #	  ZIP_CODE, ZIP_EXTENSION
    MLP_COLS    => { TYPE       => 'ARRAY',
                     DEFAULT    => [qw/PROGRAM_ID
                                       ACCOUNT_ID
                                       FIRST_NAME
                                       LAST_NAME
                                       ADDRESS1
                                       CITY
                                       STATE_CODE
                                       COUNTRY_CODE
                                       POSTAL_CODE
                                       EMAIL
                                       PHONE_DAY
                                       REPL_TYPE
                                       EMAIL_PREFERENCE
				       EXPIRY_DATE
                                       DATE_ADDED
                                       DATE_MODIFIED/], # plus TIMESTAMP
                   },

    # Communicate status, etc. between the datax action objects.
    ERROR	=> { TYPE => 'BOOL' },
    MSG		=> { TYPE => 'SCALAR',	DEFAULT	=> '' },

    # These _COUNT values are set by `import' and used by `send' to
    # decide whether to mail a report or just say "nothing changed"
    INPUT_COUNT	=> { TYPE => 'SCALAR', },
    ADD_COUNT	=> { TYPE => 'SCALAR', },
    CHANGE_COUNT=> { TYPE => 'SCALAR', },
    TOTAL_COUNT	=> { TYPE => 'SCALAR', },
};


#
# Public Methods
#
sub post_check_opts {
    my $self = shift;
    my $opts = shift;
    $self->verbose(5, "Entered post_check_opts() in ", __PACKAGE__, "\n");

    $self->_default_flags(qw/LOCAL REMOTE/);
#    $self->_default_action(qw/Validate/);	# for testing
#    $self->_default_action(qw/Download Unzipit Validate Import
#			      Export Zipit Upload
#			      Report Send/);
    return 1;
}

sub pre_run_hook {
    my $self = shift;
    $self->verbose(5, "Entered pre_run_hook() in ", __PACKAGE__, "\n");

    my $name = '$Name:  $';	# Hook for CVS Release Tag
    $name =~ s/\$Name: //;
    $name =~ s/ \$//;
    $name = 'DEVEL / NOT TAGGED' if ($name eq '');
    $self->verbose(1, "\nGNC Gold Card DataFeed Release: $name\n\n");

    my $tags = $self->effective_test_tags;
    $self->dumpHashSorted("\tTest Tags", $tags) if (defined $tags);

    $self->verbose(1, "    Verbose Level:\t",
		   GSI::Utils::Verbose->get_level(), "\n");
    if ($self->use_db) {
	$self->verbose(1, "\tDatabase:\t\t", $self->database->name, "\n");
	$self->dumpHashSorted("Database", $self->database);
    }
    else {
	$self->verbose(1, "\n-- Skipping database open --\n\n");
    }

    # date dump doesn't work yet...					#todo
#    $self->verbose(5, "    Date:\t\t");
#    foreach my $k (keys %{$self->dates}) {
#	$self->verbose(5, $self->dates->{$k}, ", ");
#    }
#    $self->verbose(5, "\n");
    $self->dumpHashSorted("  Dates", $self->dates) if defined $self->dates;

    $self->verbose(1, "    Mail To:\t", join(", ", @{$self->mail_to}), "\n");
    $self->verbose(1, "    Mail From:\t", $self->mail_from, "\n");
    $self->verbose(1, "    Store:\t", uc($self->store), "\n");
}


sub post_run_hook {
    my $self = shift;
    $self->verbose(5, "Entered post_run_hook() in ", __PACKAGE__, "\n");
}

1;
