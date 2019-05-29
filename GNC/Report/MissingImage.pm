use strict;

package GSI::DataX::GNC::Report::MissingImage;
our $VERSION = 1.00;

use base qw(GSI::DataX::GNC::Report);

sub post_check_opts
{
    my $self = shift;
    my $opts = shift;

    $self->_default_flags(qw/LOCAL /);

    $self->_default_action(qw/Create Upload/);

    return 1;
}

1;

