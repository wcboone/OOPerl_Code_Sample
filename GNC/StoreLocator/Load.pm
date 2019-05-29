use strict;
use warnings;

package GSI::DataX::GNC::StoreLocator;

use File::Basename;
use GSI::Base::Class::Universal;
use GSI::DataTranslate::Simple;

use GSI::Tie::Stat;
use GSI::Base::Paths;
use GSI::Utils::Debug;
use GSI::Utils::Verbose;
use GSI::Utils::Timing;
use GSI::DataX::GNC::StoreLocator::Files::Downloaded;
use GSI::DataX::GNC::StoreLocator::Files::Exception;

use GSI::DBI::Connection;
use GSI::Base::Paths;

sub load
{
    my $self         = shift;
    my $x            = GSI::DataTranslate::Translator->new();
    my $inputs       = GSI::DataX::GNC::StoreLocator::Files::Downloaded->existing(DATE => $self->{DATES});
    my $dbName       = $self->db_name;
    verbose(1, "Using database $dbName.\n");
    my $storeCode    = 'GNC';
    my $input_dir    = dirname(GSI::DataX::GNC::StoreLocator::Files::Downloaded->template);
    my $verboseLevel = GSI::Utils::Verbose->get_level();
    my $report       = "$ENG_REPORT_DIR/GNC_Finder.txt";
    my ($inpRows, $usedRows) = (0, 0);
    my @expanded;

# Ignore file's header, coercing its column names to match the database.
# The SALES_REP and REGION columns have no column headings in the input
# file and are often empty.

my @inColumns	= (qw/LOCATION_CODE STORE_CODE_PROV STAT LOCATION_NAME REGION MANAGER STORE_IMAGE ADDRESS1 ADDRESS2 CITY STATE_CODE POSTAL_CODE COUNTRY_CODE PHONE_NUMBER FAX_NUMBER EMAIL_ADDRESS OPENING_TIME_MON CLOSING_TIME_MON OPENING_TIME_TUE CLOSING_TIME_TUE OPENING_TIME_WED CLOSING_TIME_WED OPENING_TIME_THU CLOSING_TIME_THU OPENING_TIME_FRI CLOSING_TIME_FRI OPENING_TIME_SAT CLOSING_TIME_SAT OPENING_TIME_SUN CLOSING_TIME_SUN MALL_PLAZA_NAME MESSAGE MAP_URL DIRECTION_URL EVENTS SPECIAL_SERV DRIVE_DIRECTION MODIFIED_DATE MODIFIED_BY STORE_INFO_URL SHIP_TO_STORE LATITUDE LONGITUDE ADDRESS3 ADDRESS4 /);
my $inCols	= join("|", @inColumns);

my @loadColumns	= (qw/STORE_CODE LOCATION_CODE LOCATION_NAME REGION MANAGER STORE_IMAGE ADDRESS1 ADDRESS2 CITY STATE_CODE POSTAL_CODE COUNTRY_CODE PHONE_NUMBER FAX_NUMBER EMAIL_ADDRESS STORE_HOURS OPENING_TIME_MON CLOSING_TIME_MON OPENING_TIME_TUE CLOSING_TIME_TUE OPENING_TIME_WED CLOSING_TIME_WED OPENING_TIME_THU CLOSING_TIME_THU OPENING_TIME_FRI CLOSING_TIME_FRI OPENING_TIME_SAT CLOSING_TIME_SAT OPENING_TIME_SUN CLOSING_TIME_SUN MALL_PLAZA_NAME MESSAGE MAP_URL DIRECTION_URL EVENTS SPECIAL_SERV DRIVE_DIRECTION STORE_INFO_URL SHIP_TO_STORE LATITUDE LONGITUDE ADDRESS3 ADDRESS4/);
my $loadCols	= join(", ", @loadColumns);
my @importAllColumns= (@loadColumns, qw/ACTION_CD/);

# Use this for INS and UPD records.
my $loadSQL = <<"END_LOAD_SQL";
INSERT into store_location_feed ( $loadCols, STATUS, CREATE_DATE, ACTION_CD)
--values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,  'A', SYSDATE, 'INS')
values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'A', SYSDATE, 'INS')
END_LOAD_SQL

my $existingSQL = <<"END_EXISTING_SQL";
SELECT      $loadCols
FROM        store_location
WHERE       store_code = '$storeCode'
AND status like 'A%'
--AND rownum < 1
END_EXISTING_SQL

my $importSQL = <<"END_IMPORT_SQL";
INSERT INTO store_location_feed ( $loadCols, STATUS, CREATE_DATE, ACTION_CD)
--VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, 'A', SYSDATE,?)
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,'A', SYSDATE,?)
END_IMPORT_SQL

my $delSQL = <<"END_DEL_SQL";
INSERT INTO store_location_feed ( STORE_CODE, LOCATION_CODE, STATUS, LOCATION_NAME, COUNTRY_CODE, CREATE_DATE, ACTION_CD)
    VALUES ( ?, ?, 'Del', ?, ?, SYSDATE, 'DEL')
END_DEL_SQL

#my $retainSQL = <<"END_RETAIN_SQL";
#SELECT MANAGER,
#        STORE_IMAGE,
#        ADDRESS2,
#        FAX_NUMBER,
#        EMAIL_ADDRESS,
#        MALL_PLAZA_NAME,
# --       MESSAGE,
#        MAP_URL,
#        DIRECTION_URL,
#        EVENTS,
#--        SPECIAL_SERV,
#        DRIVE_DIRECTION,
#        STORE_INFO_URL,
#        SHIP_TO_STORE,
#        ADDRESS3,
#        ADDRESS4,
#	STORE_TIME_OFFSET
#    FROM
#        store_location
#    WHERE
#        store_code = ?
#    AND location_code = ?
#END_RETAIN_SQL

my ($updateRows,$deleteRows,$insertRows) = (0,0,0);

    $self->debug(1, "load() called for $self.\n");
    my $t = start_timing(1, "GNC Store Locator load on $dbName");

    local $GSI::Base::Class::Universal::ExpandRegex = qr/\$\$\{(.+?)\}/;

    if (scalar(@{$inputs->files()}) == 0)
    {
        $self->verbose(1, "No files found to load.\n");
        return 1;
    }
    my $exceptions =
           GSI::DataX::GNC::StoreLocator::Files::Exception->new->new_file->path;

    my $error_map =
    [     Null          => {}
       => NewlineRemove => {}
       => Delimited     => {FILE => $exceptions, HEADER => 1}

    ];

    my $bad_sku_map = 
    [      Null     => {} 
        => MoveFile => { COLUMN => 'INPUT_FILE',
                         TO_DIR => "$input_dir/BAD_SKU",
                       }
        => Null     => {}
    ];

my $loadMap = [
       Delimited    => $inputs->list_expand
                       ({
                         FILE      => '$${PATH}',
                         HEADER    => 0,
#                         NEWLINE   => "\r\n",
                         DELIMITER => '\|',
                         COLUMNS   => \@inColumns,
                       })

      => SpaceRemove	=> { SKIP_EMPTY	=> 1,
			     EMPTY_STOP	=> 1,
        		   }

      => Debug		=> { MESSAGE	=> 'Input >>> ',
			      USE	=> $verboseLevel > 4,
			    }
     => CountRows	=> { COUNTER	=> \$inpRows,
			   }

     => SpaceRemove	=> { SKIP_EMPTY	=> 1,
			     INCLUDE	=> [qw/LOCATION_NAME/],
			     USE	=> 1,
			   }
      => RowAdd	=> { VALUES	=> { 
                                     STORE_CODE 	=> $storeCode, 
                                   },
                   },
 
     => TextMunge	=> { COLUMNS	=> [qw/LONGITUDE LATITUDE/],
			     REGEXP	=> q#s/\)//g#,
			   }
     => TextMunge	=> { COLUMNS	=> [qw/LONGITUDE LATITUDE/],
			     REGEXP	=> q#s/\(/-/g#,
			   }
     => [  ColumnMatch	=> { COLUMN	=> 'STATE_CODE',
			     MATCH	=> undef,
			   }
	=> RowAdd	=> { VALUES	=> { STATE_CODE	=> '', },
			   }
	]

     => TextMunge	=> { COLUMNS	=> [qw/CITY/],
			     REGEXP	=> q#s/,//g#,
			   }
     => TextMunge	=> { COLUMNS	=> [qw/LOCATION_NAME ADDRESS1/],
			     REGEXP	=> q#s/(\s)\s+/\1/g#,
			   }
     => TextMunge	=> { COLUMNS	=> [qw/STATE_CODE/],
			     REGEXP	=> q#s/\.//g#,
			   }
     => TextMunge	=> { COLUMN	=> [qw/POSTAL_CODE/],
			     REGEXP	=> qw#s/\s//g#,
			   }
     => TextMunge	=> { COLUMN	=> [qw/POSTAL_CODE/],
			     REGEXP	=> qw#s/^(\d{5}).*$/$1/#,
			   }
     => TextMunge	=> { COLUMN	=> [qw/POSTAL_CODE/],
			     REGEXP	=> qw#s/^(\d{4})$/0$1/#,
			   }

     => ToUpper		=> { COLUMN	=> [qw/STATE_CODE/],
			   }

     => ToUpper		=> { COLUMN	=> [qw/COUNTRY_CODE/],
			   }
     => [  ColumnMatch	=> { COLUMN	=> 'COUNTRY_CODE',
			     MATCH	=> undef,
			   }
	=> RowAdd	=> { VALUES	=> { COUNTRY_CODE	=> 'US', },
			   }
	]

     => [ ColumnMatch => { COLUMN  => 'COUNTRY_CODE',
                              MATCH   => qr/^VI$/,
                            }
        => TextMunge    => { COLUMN     => [qw/COUNTRY_CODE/],
                             REGEXP     => qw#s/^VI$/VG/#,
                           }
        ]
     => [ ColumnMatch => { COLUMN  => 'COUNTRY_CODE',
                              MATCH   => qr/^CA$/,
                            }
        => TextMunge    => { COLUMN     => [qw/STATE_CODE/],
                             REGEXP     => qw#s/^PQ$/QC/#,
                           }
        ]

     => TextMunge	=> { COLUMN	=> [qw/COUNTRY_CODE/],
			     REGEXP	=> qw#s/^USA$/US/#,
			   }
     => TextMunge	=> { COLUMN	=> [qw/COUNTRY_CODE/],
			     REGEXP	=> q#s/ //g#,
			   }
     => TextMunge	=> { COLUMN	=> [qw/COUNTRY_CODE/],
			     REGEXP	=> qw#s/^UNITEDSTATES$/US/#,
			   }
     => [ ColumnNotMatch => { COLUMN  => 'COUNTRY_CODE',
                              MATCH   => qr/^US$/,
                            }
     => [ ColumnNotMatch => { COLUMN  => 'COUNTRY_CODE',
                              MATCH   => qr/^CA$/,
                            }
        => CopyCol       => { FROM        => 'NULL_STATE_CODE',
                              TO          => 'STATE_CODE',
                            }
	]
	]
      => Debug		=> { MESSAGE	=> 'Before FormatStoreHours Modified Input >>> ',
	     USE	=> $verboseLevel > 6,
			   }
      => FormatStoreHours => { }
      => Debug		=> { MESSAGE	=> 'After FormatStoreHours Modified Input >>> ',
			     USE	=> $verboseLevel > 6,
			   }

        # The CHANGE_FLAG from TableChange is:
        # A - Add:       input record not in database
        # C - Change:    input record differs from database
        # D - Delete:    database record not in master file
        # N - No change: identical records
        #
        # For this feed, apply the following to the staging table
        # A => add a new store
        # C => change to existing store
        # D => delete a closed store
        # N => no change, ignore

        => TableChange  => { DATABASE   => $dbName,
                             SQL        => $existingSQL,
                             INDEX      => 'LOCATION_CODE',
                             CHANGE_COL => 'CHANGE_FLAG',
                             WANTED     => [qw/A C D/],
                             COLUMN_CASE=> 'UPPER',
                           }
						   
        => Debug        => { MESSAGE    => ">>> TableChange Output (importMap) ",
                             USE        => $verboseLevel > 3,
                           }

        # INS...
        => [  ColumnMatch       => { COLUMN     => 'CHANGE_FLAG',
                                     MATCH      => 'A',
                                   }
								   
           => RowAdd            => { VALUES     =>
                                     { ACTION_CD                => 'INS',
                                     },
                                   }
           => CountRows         => { COUNTER    => \$insertRows, }
           => Debug             => { MESSAGE    => ">>> Stage INS ",
                                     USE        => $verboseLevel > 5,
                                   }
           => [ ColumnNotMatch => { COLUMN  => 'COUNTRY_CODE',
                                    MATCH   => qr/^US$/,
                            }
             => [ ColumnNotMatch => { COLUMN  => 'COUNTRY_CODE',
                                      MATCH   => qr/^CA$/,
                            }
               => CopyCol       => { FROM        => 'NULL_STATE_CODE',
                                     TO          => 'STATE_CODE',
                            }
	       ]
	      ]
           => DBTable           => { DB_NAME    => $dbName,
                                     SQL        => $importSQL,
                                     ROW_ARG    => \@importAllColumns,
                                     USE        => 1,
                                     ERROR_MAP => $error_map,
                                   }
	   ]

        # DEL...
        => [  ColumnMatch       => { COLUMN     => 'CHANGE_FLAG',
                                     MATCH      => 'D',
                                   }
           => RowAdd            => { VALUES     => { ACTION_CD => 'DEL', },
                                   }
           => CountRows         => { COUNTER    => \$deleteRows, }
           => Debug             => { MESSAGE    => ">>> Stage DEL ",
                                     USE        => $verboseLevel > 5,
                                   }
           => DBTable           => { DB_NAME    => $dbName,
                                     SQL        => $delSQL,
                                     ROW_ARG    => [qw/STORE_CODE LOCATION_CODE
                                                       LOCATION_NAME
                                                       COUNTRY_CODE/],
                                     USE        => 1,
                                     ERROR_MAP => $error_map,
                                   }
								   
           ]

        # UPD...
        => [  ColumnMatch       => { COLUMN     => 'CHANGE_FLAG',
                                     MATCH      => 'C',
                                   }
           => RowAdd            => { VALUES     => { ACTION_CD => 'UPD', },
                                   }
           # For current stores, retain existing fields. SMP 10472 request this logic removed
#           => DBRowAdd          => { DB_OPTS    => { DB_NAME    => $dbName,
#                                                     SQL        => $retainSQL,
#                                                   },
#                                     ROW_ARG    => [qw/STORE_CODE LOCATION_CODE/],
#                                     USE        => 1,
#                                   }
								   
           => CountRows         => { COUNTER    => \$updateRows, }
           => Debug             => { MESSAGE    => ">>> Stage UPD ",
                                     USE        => $verboseLevel > 3,
                                   }
     => [ ColumnNotMatch => { COLUMN  => 'COUNTRY_CODE',
                              MATCH   => qr/^US$/,
                            }
     => [ ColumnNotMatch => { COLUMN  => 'COUNTRY_CODE',
                              MATCH   => qr/^CA$/,
                            }
        => CopyCol       => { FROM        => 'NULL_STATE_CODE',
                              TO          => 'STATE_CODE',
                            }
	]
	]
      => Debug		=> { MESSAGE	=> 'End of Line >>> ',
	     USE	=> $verboseLevel > 3,
			   }
           => DBTable           => { DB_NAME    => $dbName,
                                     SQL        => $importSQL,
                                     ROW_ARG    => \@importAllColumns,
                                     USE        => 1,
                                     ERROR_MAP => $error_map,
                                   }
								   
           ]

     => CountRows	=> { COUNTER	=> \$usedRows,
			   }

     => Delimited	=> { FILE_NAME	=> $report,
			     DELIMITER	=> '|',
		      	     HEADER	=> 1,
			     USE	=> 1,
			   }
];
translate($loadMap);

verbose(1, "$storeCode master file has $inpRows rows.\n");
verbose(1, "$storeCode master file required $updateRows updates.\n");
verbose(1, "$storeCode master file required $deleteRows deletes.\n");
verbose(1, "$storeCode master file required $insertRows inserts.\n");
#my $ignoredRows = $inpRows - $usedRows;
#verbose(1, "\tUsed $usedRows rows ($ignoredRows empty LOCATION_NAMEs excluded).\n");
verbose(1, "\tCreated $usedRows rows.\n");

stop_timing($t);
    return 1;
}

1;
