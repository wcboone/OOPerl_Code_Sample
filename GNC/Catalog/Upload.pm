#
# $Id: Upload.pm,v 1.1 2011/10/31 18:11:38 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog;

use GSI::DataX::GNC::Catalog::Files::Local;
use GSI::DataX::GNC::Catalog::Files::Remote;


sub upload
{
    my $self   = shift;
    my $opts   = {};
    my $dates  = $self->dates();
    my ($from, $to);

    if (defined($dates))
    {
        $opts->{DATES}   = $dates->value();
        $opts->{CACHED}  = 1;

        $from = GSI::DataX::GNC::Catalog::Files::Local->existing($opts);
    }
    else
    {
        $from = GSI::DataX::GNC::Catalog::Files::Local->existing();

        my $files  = $from->files();
        my @sorted = sort {$a->date->epoch <=> $b->date->epoch} @$files;
        my $last   = $sorted[-1];

        $from->files([$last]);
    }

    $to = GSI::DataX::GNC::Catalog::Files::Remote->new();

    return $from->copy($to);
}

1;
