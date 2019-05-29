#
# $Id: Export.pm,v 1.1 2005/10/31 18:01:38 donohuet Exp $
#

use strict;

package GSI::DataX::GNC::Export;
our $VERSION = 1.00;

use GSI::DataX::GNC::Base;
our @ISA = qw(GSI::DataX::GNC::Base);

use GSI::File::Set;
use GSI::DBI::Connection;

use GSI::OptArg::ClassAttr
{
    'GSI::File::Set' => [qw/LS_MODE/],

   ACTIONS     => { MODIFY            => 1,
                    DEFAULT           => [qw/Files Export Upload/],
                  },

   # File Set List Flags
   LOCAL       => { TYPE              => 'BOOL' },
   REMOTE      => { TYPE              => 'BOOL' },
};

sub post_check_opts
{
    my $self = shift;
    my $opts = shift;

    $self->{LOCAL} = $self->{REMOTE} = 1
      if ( !defined($self->{LOCAL}) && !defined($self->{REMOTE}) );

    return 1;
}

1;
