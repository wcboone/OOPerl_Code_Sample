
use strict;

package GSI::DataX::GNC::StoreLocator;

use GSI::DataX::GNC::StoreLocator::Files::Downloaded;

sub check
{
    my $self   = shift;
    my $checks = $self->checks();
    my $opts   = {};
    my $dates  = $self->dates();
    my $what;

    $opts->{DATES}   = $dates->value() if (defined($dates));
    $opts->{CACHED}  = 1;

    if ($what = $checks->{Download})
    {
        $what = lc $what;
        $self->_check_copy('GSI::DataX::GNC::StoreLocator::Files::Remote',
                           'GSI::DataX::GNC::StoreLocator::Files::Downloaded',
                           $opts, ($what eq 'fix') ? 'download' : undef);
    }

    return 1;
}

1;
