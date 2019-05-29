#
# Report changes to GNC GoldCard data.
#

#
# $Id: Report.pm,v 1.4 2012/08/24 06:06:47 kakkarn Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataX::GNC::GoldCard::Files::Report;

use GSI::DataTranslate::Simple;


sub report {
    my $self = shift;
    $self->verbose(1, "Entered 'report' (", __PACKAGE__, ")\n");

    my $error = $self->{ERROR};
    my $errorMsg = $self->{MSG};
    if ($error) {
	$self->verbose(1, "Skipping 'report' due to errors.\n");
    }
    else {
	my $reportSet  = GSI::DataX::GNC::GoldCard::Files::Report->new();
	my $reportName = $reportSet->{SET_NAME};
	my $reportPath = $reportSet->new_file->path() if (defined($reportSet));

	if (!defined($reportPath) || ($reportPath eq "")) {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error!  'Report' file not created.\n";
	    $self->verbose(1, "\n!!! $self->{MSG}\n\n");
	    warn("\n!!! $self->{MSG}\n\n");
	}
	else {
	    $self->verbose(1, "Creating $reportSet->{SET_NAME}: $reportPath\n");
	    my @stores = @{$self->{STORES}};
	    $self->verbose(1, "Stores = @stores\n");
	    foreach my $store (@stores) {
		$self->_report($store, $reportPath);

		### Temp! Really should create & send a report per store #todo
		#   But!  once the store_codes are all in sync it won't matter,
		#   and until then just run each store_code in a separate feed.
		#   Problem is, each store re-uses the same report file, so
		#   it's best ro run one feed per store anyway.
		last if ($store eq 'GNC');
	    }
	}
    }
    return 1;
}


sub _report {
    my $self	= shift;
    my $store	= shift;
    my $path	= shift;

    my $dbName = $self->{DB_NAME};
    $self->verbose(1, "DB_NAME = \"$dbName\"\n");

    # These are in GoldCard.pm; they are shared between Import and Report.
#todo
    my @storeColumns	= @{$self->{STORE_COLUMNS}};
    my $storeCols	= join(", ", @storeColumns);
    my @gmtColumns	= @{$self->{GMT_COLUMNS}};
    my $gmtCols		= join(", ", @gmtColumns);

    # These differ between Import and Report.
#todo
    my @delColumns	= (qw/STORE_CODE LOCATION_CODE STATUS LOCATION_NAME/);
    my $delCols		= join(", ", @delColumns);

    $self->verbose(3, "storeCols = \"$storeCols\"\n");
    $self->verbose(3, "gmtCols = \"$gmtCols\"\n");

    my $existingSQL = <<"END_EXISTING_SQL";
    SELECT	$storeCols, $gmtCols
    FROM	store_location
    WHERE	store_code = '$store'
	    AND status like 'A%'
    ORDER BY	TO_NUMBER(location_code)
END_EXISTING_SQL

    my $stagedSQL = <<"END_STAGED_SQL";
    SELECT	$storeCols, $gmtCols
    FROM	store_location_feed
    WHERE	store_code = '$store'
	    AND action_cd  = ?
	    AND load_date IS NULL
--	    AND create_date like ... just today's records?
    ORDER BY	TO_NUMBER(location_code)
END_STAGED_SQL

    # For DEL records only want store_code, location_code
    my $delSQL = <<"END_STAGED_SQL";
    SELECT	store_code, location_code, status, location_name
    FROM	store_location_feed
    WHERE	store_code = '$store'
	    AND action_cd  = 'DEL'
	    AND load_date IS NULL
--	    AND create_date like ... just today's records?
    ORDER BY	TO_NUMBER(location_code)
END_STAGED_SQL

    # Create an excel report containing four worksheets:  Existing, Additions,
    # Deletions, and Updates; sorted by location_code within each worksheet.
    my $map = [
	[  DBQuery	=> { DB_NAME	=> $dbName,
			     SQL	=> $existingSQL,
			   },
	   DBQuery	=> { DB_NAME	=> $dbName,
			     BIND_PARAM	=> [ 'INS' ],	# action_cd = 'INS'
			     SQL	=> $stagedSQL,
			   },
	   DBQuery	=> { DB_NAME	=> $dbName,
			     SQL	=> $delSQL,	# action_cd = 'DEL'
			   },
	   DBQuery	=> { DB_NAME	=> $dbName,
			     BIND_PARAM	=> [ 'UPD' ],	# action_cd = 'UPD'
			     SQL	=> $stagedSQL,
			   },
	]
	=> Excel	=> { FILE	=> $path,
			     SHEET	=> 'Existing', },
			   { SHEET	=> 'Additions',  },
			   { SHEET	=> 'Deletions' },
			   { SHEET	=> 'Updates' },
    ];
    translate($map);

    return 1;
}

1;
