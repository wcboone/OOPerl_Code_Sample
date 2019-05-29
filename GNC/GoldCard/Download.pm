#
# Download the GNC GoldCard Customer file.
#

#
# $Id: Download.pm,v 1.6 2007/01/22 18:21:03 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataX::GNC::GoldCard::Files::RemoteIn;
use GSI::DataX::GNC::GoldCard::Files::ZipIn;


sub download {
    my $self = shift;
    my $opts = {};

    $self->verbose(1, entrystamp('download', __PACKAGE__));

    $opts->{DATES}  = $self->dates() || 'today';
    $opts->{CACHED} = 1;

    my $from = GSI::DataX::GNC::GoldCard::Files::RemoteIn->existing($opts);
    if (scalar @{$from->files()} == 0) {
	$self->verbose(1, "No GoldCard file(s) found to download.\n");
	exit 0;
    }

    my $to   = GSI::DataX::GNC::GoldCard::Files::ZipIn->new($opts);
    my $changedOnly = 1;
    if ($from->copy($to, $changedOnly)) {
	$from->remove();
    }

    return 1;
}

1;
