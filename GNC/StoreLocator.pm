use strict;

package GSI::DataX::GNC::StoreLocator;
our $VERSION = 1.00;

use GSI::DataX::GNC::Base;
our @ISA = qw(GSI::DataX::GNC::Base);

use GSI::OptArg::ClassAttr
{
   ACTIONS       => { MODIFY   => 1,
                      DEFAULT  => [qw/Files Download Load/
                                  ],
                    },

   # File Set List Flags
   REMOTE        => {TYPE      => 'BOOL'},
   DOWNLOADED    => {TYPE      => 'BOOL'},

   CHECKS        => { TYPE     => 'Flags',
                      DEFAULT  => [qw/Files Download Load/],
                    },
   TRANSFER      => {TYPE      => 'BOOL', DEFAULT => 1},
   OVERWRITE     => { TYPE     => 'BOOL', DEFAULT => 0 },
   DB_NAME     => { TYPE       => 'SCALAR',
                    MODIFY     => 1,
                    #DEFAULT    => 'staging2' #'developer'  # 'Catman' for production
                    DEFAULT    => 'Catman'
                  },
};

sub post_check_opts
{
    my $self = shift;
    my $opts = shift;

    $self->{REMOTE} = $self->{DOWNLOADED} = 1
      if ( !defined($self->{REMOTE}) && !defined($self->{DOWNLOADED}));
    return 1;
}

1;
