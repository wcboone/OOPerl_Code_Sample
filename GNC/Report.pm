
use strict;

package GSI::DataX::GNC::Report;
our $VERSION = 1.00;

use base qw/GSI::DataX::GNC::Import/;
our @ISA =qw(GSI::DataX::GNC::Import);

warn "Loaded ", __PACKAGE__,"\n" if (GSI::Utils::Verbose->get_level() > 2);

use GSI::OptArg::ClassAttr {

   DB_NAME     => { TYPE => 'SCALAR',
                     MODIFY => 1,
                     DEFAULT    => 'CATMAN',  # 'Catman' for production
                   },

   ACTIONS         => { MODIFY         => 1,
                         DEFAULT        => [qw/Create/],
                       },

   STORE          => { TYPE         => 'StoreCode',
                       DEFAULT      => qw/GNC/,
                       ALIASES      => [qw/STORE_CODE/],
                     },

   ELEMENT_TYPE   => { MODIFY         => 1,
                       TYPE         => 'ARRAY' ,
                       DEFAULT      => (),
                     },
};

sub post_check_opts
{
    my $self = shift;
    my $opts = shift;

    $self->_default_flags(qw/LOCAL REMOTE/);
    $self->_default_action(qw/Create Upload/);

    return 1;
}

1;

