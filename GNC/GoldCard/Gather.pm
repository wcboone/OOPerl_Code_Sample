#
# $Id: Gather.pm,v 1.2 2007/02/27 15:41:17 feeds Exp $ 
#

use strict;

package GSI::DataX::GNC::GoldCard;

use GSI::Base::Paths;
use GSI::DataTranslate::Simple;
use GSI::DataTranslate::Input::Delimited;
use GSI::DataX::GNC::GoldCard::Files::Export;
use File::Copy;

sub gather
{
   my $self   = shift;
   my ($type, $map, $skus);
   my $verboseLevel = GSI::Utils::Verbose->get_level();

   my $dates    = $self->{DATES};
   my $opts = {};
   my $start    = $dates->start if (defined($dates));
   my $end      = $dates->end   if (defined($dates));
   my $existing = GSI::DataX::GNC::GoldCard::Files::Export->existing
                  (DATES => $dates);
#
#  setting up the output dataset
#
   my $exportSet = GSI::DataX::GNC::GoldCard::Files::Export->new($opts);
   my $exportName = $exportSet->{SET_NAME};
   my $exportPath = $exportSet->new_file->path;

   if (!defined($exportPath) || ($exportPath eq "")) {
       $self->{ERROR} = 1;
       $self->{MSG} = "Error!  $exportName not found\n";
       $self->verbose(1, "\n!!! $self->{MSG}\n\n");
       warn("\n!!! $self->{MSG}\n\n");
   }
   else {
         $self->verbose(1, "Using file \"$exportPath\"\n");
        }
#
#  input file processing
#
   my @files    = $existing->files();

   if ( !defined($start) && !defined($end) )
   {
       my ($file, @use);

       while ($file = pop(@files))
       {
           unshift(@use, $file);
           last if ($file->{TYPE} eq 'f');
       }

       @files = @use;
   }

   if (scalar(@files) == 0)
   {
       die "No existing files found for GNC Gather.\n";
   }

#
#  Gathering the files
#

   my ($input, $rows, $n, $r);
   my %h = ();

   open OUTPUT, "> $exportPath" or die "Can't open $exportPath : $!"; 

   foreach my $file (@files) 
   {
       $self->verbose(1, "Reading $file->{PATH} ...\n");
       open INPUT, "< $file->{PATH}" or die "Can't open $file->{PATH} : $!";
       while(<INPUT>)
       { 
         my @a = split(/\t/);
         if (exists $h{$a[1]}) { print $a[1] . " Exists ... Skipping ...  \n"; }
         if (! exists $h{$a[1]}) { print OUTPUT $_; ++$h{$a[1]}; }
       }
       close INPUT;
       my $newpath = $file->{PATH};
       $newpath =~ s/^.*\///;
       $newpath = "/tmp/" . $newpath;
       move ($file->{PATH}, $newpath);
   }
   
   close OUTPUT;

    return 1;
}

1;
