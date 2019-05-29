#
# Validate the downloaded GNC Gold Card file before using.
#

#
# $Id: Validate.pm,v 1.7 2005/12/09 00:09:15 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataTranslate::Simple;
use GSI::DataX::GNC::GoldCard::Files::Local;

use GSI::OptArg::ClassAttr {
#    DATE	=> { MODIFY	=> 1,
##		     DEFAULT	=> { START => '24 hours ago', },
#		     DEFAULT	=> { START => '2 weeks ago', },
#		   },
};

sub validate {
    my $self = shift;
    $self->verbose(1, entrystamp('validate', __PACKAGE__));

    my $opts = {};
#    $opts->{DATES}  = $self->dates() || 'today';
    $opts->{CACHED} = 1;

    my $error = 0;
    my $msg = "";

    my $localSet = GSI::DataX::GNC::GoldCard::Files::Local->existing($opts);
#    if (!defined($localName)) {
#	$error = 1;
#	$msg = "Error!  GNC GoldCard file not found\n";
#    }
#
#   if (!$error ...

    my $localName = $localSet->{SET_NAME};
    my $localPath = $localSet->newest->{PATH};

    $localPath = $self->{INPUT_FILE} if (defined $self->{INPUT_FILE});

    if (!defined $localPath or $localPath eq "") {
	$error = 1;
	$msg = "Error!  GNC GoldCard file not found: " .
	  undefined($localPath) . "\n";
    }

    if ($error) {
	$self->{ERROR} = $error;
	$self->{MSG} = $msg;
	$self->verbose(1, "\n!!! $self->{MSG}\n\n");
	warn("\n!!! $self->{MSG}\n\n");
	return 1;
    }

    $self->verbose(1, "Pre-Validating file \"$localPath\"\n");
    my $tMark0 = start_timing(1, "\tPre-validate");
    my $nRows = qx/wc -l $localPath/;
    stop_timing($tMark0);
    chomp($nRows);
    $nRows =~ s/^(\s*)(\d+)\s+.*/$2/;
    $self->verbose(1, "$localName \"$localPath\" has $nRows rows\n");

    #
    # Sanity checks:  look for garbled rows.
    #
    $self->verbose(1, "Validating file \"$localPath\"\n");
    my $undefCols = 0;
    my @gncCols	= @{$self->{GNC_COLS}};
    my $tMark = start_timing(1, "\tValidate");
    my $valMap = [
	   Delimited	=> { FILE_NAME	=> $localPath,
			     COLUMNS	=> \@gncCols,
			   }
	# Check for undef'd last column -- indicates garbled row.
	=> [  ColumnIn	=> { COLUMN	=> 'GSI_GNC_GOLD_CARD_EXPIRATION_DATE',
			     LIST	=> [ undef ],
			   }
	   => CountRows	=> { COUNTER	=> \$undefCols, }
#	   => Debug	=> { MESSAGE	=> ">>> UNDEF (validateMap) ",
#			     USE	=> $verboseLevel > 4,
#			   }
	   ]
    ];
    translate($valMap);
    stop_timing($tMark);

    $self->verbose(1, "$localName has $nRows rows\n");

    my $rowThreshold = $self->{MIN_ROW_COUNT};
    if ($nRows <= 0) {
	$error = 1;
	$msg = "zero rows received";
    }
    elsif ($nRows < $rowThreshold) {
	$error = 1;
	$msg = "fewer than $rowThreshold rows received";
    }
    elsif (0 < $undefCols) {
	$error = 1;
	$msg = "last column (GMToffset) missing in $undefCols rows";
    }

    $self->{ERROR} = $error;
    if ($error) {
	$self->{MSG} = "Error!  $localName ignored: $msg.";
	$self->verbose(1, "\n!!! $self->{MSG}\n\n");
	warn("\n!!! $self->{MSG}\n\n");
	return 1;
    }

    return 1;
}

1;
