
use strict;

package GSI::DataX::GNC::StoreLocator;

use POSIX qw(strftime);
use File::Basename;
use GSI::DataX::GNC::StoreLocator::Files::Remote;
use GSI::DataX::GNC::StoreLocator::Files::Downloaded;
use GSI::DataX::GNC::StoreLocator::Files::Archived;
use GSI::DataTranslate::Simple;

sub download
{
    my $self      = shift;
    my $opts      = {};
    my $dates     = $self->dates();
    my ($from, $to);
    my ($got, $got_file, @files);

    $self->debug(2, "download() called for $self.\n");
    $opts->{DATES}   = $dates->value() if (defined($dates));
    $opts->{CACHED}  = 1;

    $from = GSI::DataX::GNC::StoreLocator::Files::Remote->existing($opts);
    $to   = GSI::DataX::GNC::StoreLocator::Files::Downloaded->new($opts);
    $from->copy($to);
    $got  = $from->map_to($to);

    foreach my $file ($to->files())
    {
        $self->verbose(1, "GNC StoreLocator file : $file->{PATH}\n");
    }

    #archive all files we just fetched and processed
    foreach my $file ($from->files())
    {
        push(@files, $file) if ( defined($got_file = $got->{$file}) &&
                                 $got_file->connect->exists() );
    }

    $from->{FILES} = \@files;

    $to = GSI::DataX::GNC::StoreLocator::Files::Archived->new($opts);
    $from->map_to($to);
    $from->rename($to);

}
1;
