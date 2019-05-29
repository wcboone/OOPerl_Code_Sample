#
# Unzip the inbound GNC GoldCard Customer file.
#

#
# $Id: Unzipit.pm,v 1.2 2005/12/08 16:57:43 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use File::Copy;
use GSI::Archive::Zip;
use GSI::DataX::GNC::GoldCard::Files::ZipIn;
use GSI::DataX::GNC::GoldCard::Files::Local;

sub unzipit {
    my $self = shift;
    my $opts = {};

    $self->verbose(1, entrystamp('unzipit', __PACKAGE__));

    $opts->{CACHED} = 1;

    my $from = GSI::DataX::GNC::GoldCard::Files::ZipIn->existing($opts);
    my $to   = GSI::DataX::GNC::GoldCard::Files::Local->new($opts);

#    if (defined $from and defined $from->newest) {
#	foreach my $each_from (@$order) {
#	    my $m_to = $map->{$each_from};
#	    my $d_from = $each_from->connect();
#	    my $d_to = $m_to->connect();
#	    $self->verbose(3, "d_to->full_path = ", $d_to->full_path(), "\n");
#	    $self->verbose(3, "d_from->full_path = ", $d_from->full_path(),"\n");
#	}
#    }

    my $sts  = 0;
    if (defined $from and defined $from->newest) {
	$self->dumpHashSorted('from', $from);
	$self->dumpHashSorted('to', $to);

	# Unzip it in-place, in the zipin directory.
	my $unzipIt = sub {
	    my $from = shift;
	    my $to   = shift;
	    GSI::Archive::Zip::unzip($from->full_path());
	};

	$sts = $from->filter($to, $unzipIt);
	if (!$sts) {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error!  Failed to unzip GNC GoldCard file\n";
	}

	# Move it to the local directory.
	my ($order, $map) = $from->map_to($to);
	my $firstFrom	  = @$order[0];
	my $mappedTo	  = $map->{$firstFrom};
	my $connTo	  = $mappedTo->connect();
	my $connFrom	  = $firstFrom->connect();

	my $fromPath	=  $connFrom->full_path();
	# hack! extracted file name based on archive name, but without
	# the timestamp and with .txt instead of .zip
	($fromPath = lc($fromPath)) =~ s/-\d*-\d*\.zip/.txt/;
	my $toPath =  $connTo->full_path();

	$self->verbose(3, "move $fromPath to $toPath\n");

	$sts = move($fromPath, $toPath);
	if (!$sts) {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error!  Failed to move GNC GoldCard file\n";
	}
    }
    else {
	$self->{ERROR} = 1;
	$self->{MSG} = "Error!  No GNC GoldCard inbound Zip files\n";
    }

    if ($self->{ERROR}) {
	warn("\n!!! $self->{MSG}\n\n");
    }

    return $sts;
}

1;
