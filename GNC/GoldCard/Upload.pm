#
# Upload the GNC GoldCard file
#

#
# $Id: Upload.pm,v 1.6 2005/12/14 01:55:04 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataX::GNC::GoldCard::Files::ZipOut;
use GSI::DataX::GNC::GoldCard::Files::RemoteOut;

sub upload {
    my $self = shift;
    my $opts = {};

    $self->verbose(1, entrystamp('upload', __PACKAGE__));

    $opts->{DATES}  = $self->dates() || 'today';
    $opts->{CACHED} = 1;

    my $from = GSI::DataX::GNC::GoldCard::Files::ZipOut->existing($opts);
    my $to   = GSI::DataX::GNC::GoldCard::Files::RemoteOut->new();
    $from->copy($to);

    return 1;
}

1;
