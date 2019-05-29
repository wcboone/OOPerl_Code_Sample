#
# $Id: Files.pm,v 1.1 2011/10/31 18:11:38 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog;

use GSI::DataX::GNC::Catalog::Files::Local;
use GSI::DataX::GNC::Catalog::Files::Remote;

sub files
{
    my $self    = shift;
    my $opts    = {};
    my $set;

    $opts->{LS_MODE} = $self->{LS_MODE};
    $opts->{CACHED}  = 1;
    $opts->{DATES} = $self->{DATES};

    if ($self->{LOCAL})
    {
        $set = GSI::DataX::GNC::Catalog::Files::Local->existing($opts);
        $set->list();
    }

    if ($self->{REMOTE})
    {
        delete $opts->{DATES};
        $set = GSI::DataX::GNC::Catalog::Files::Remote->existing($opts);
        $set->list();
    }
}

1;
