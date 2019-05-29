
use strict;

package GSI::DataX::GNC::StoreLocator;

use GSI::DataX::GNC::StoreLocator::Files::Remote;
use GSI::DataX::GNC::StoreLocator::Files::Downloaded;
use GSI::DataX::GNC::StoreLocator::Files::Archived;

sub files
{
    my $self   = shift;
    my $opts   = {};
    my $dates  = $self->dates();
    my $set;

    $opts->{DATES}   = $dates->value() if (defined($dates));
    $opts->{LS_MODE} = $self->{LS_MODE};
    $opts->{CACHED}  = 1;

    if ($self->{REMOTE})
    {
        $set = GSI::DataX::GNC::StoreLocator::Files::Remote->existing($opts);
        $set->list();
    }

    if ($self->{DOWNLOADED})
    {
        $set = GSI::DataX::GNC::StoreLocator::Files::Downloaded->existing($opts);
        $set->list();
    }

    if ($self->{ARCHIVED})
    {
        $set = GSI::DataX::GNC::StoreLocator::Files::Archived->existing($opts);
        $set->list();
    }
}

1;
