#
# $Id: Upload.pm,v 1.1 2012/09/11 13:49:30 lagishettys Exp $
#

use strict;

package GSI::DataX::GNC::Report::MissingImage;

use GSI::DataX::GNC::Report::MissingImage::Files::Local;
use GSI::DataX::GNC::Report::MissingImage::Files::Remote;


sub upload
{
    my $self   = shift;
    my $opts   = {};
    my ($from, $to);

    $from = GSI::DataX::GNC::Report::MissingImage::Files::Local->existing($opts);
    $to = GSI::DataX::GNC::Report::MissingImage::Files::Remote->new();

    return $from->copy($to);
}

1;

