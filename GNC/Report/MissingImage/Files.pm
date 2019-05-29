
use strict;

package GSI::DataX::GNC::Report;

use GSI::DataX::GNC::Report::MissingImage::Files::Local;
use GSI::DataX::GNC::Report::MissingImage::Files::Remote;

sub files
{
    my $self = shift;
    my $opts = {};
    my $set;

    $opts->{LS_MODE} = $self->{LS_MODE};
    $opts->{CACHED}  = 1;
    $opts->{DATES}   = $self->{DATES};

    if ($self->{LOCAL})
    {
        $set = GSI::DataX::GNC::Report::MissingImage::Files::Local->existing($opts);
        $set->list();
    }

    if ($self->{REMOTE})
    {
        delete $opts->{DATES};
        $set = GSI::DataX::GNC::Report::MissingImage::Files::Remote->existing($opts);
        $set->list();
    }
}

1;

