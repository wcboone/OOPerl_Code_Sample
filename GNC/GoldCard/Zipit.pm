#
# Zip the outbound GNC GoldCard Customer file.
#

#
# $Id: Zipit.pm,v 1.9 2005/12/28 20:08:09 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use Cwd;
use File::Copy;
use File::Basename;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
#use GSI::File::FullPath;
use GSI::DataX::GNC::GoldCard::Files::Export;
use GSI::DataX::GNC::GoldCard::Files::ZipOut;

use GSI::OptArg::ClassAttr {
    DATE	=> { MODIFY	=> 1,
		     DEFAULT	=> { START => '24 hours ago', },
		   },
};

sub zipit {
    my $self = shift;
    my $status = 1;
    $self->verbose(1, entrystamp('zipit', __PACKAGE__));

    my $error = $self->{ERROR};
    if ($error) {
	$self->verbose(1, "Skipping 'zipit' due to errors.\n");
    }
    else {
	$status = $self->_zipit();
    }
    return $status;
}

#
# Private Methods
#

#
# Problems:
# a) handles single file only, no support for file sets
# b) file is assumed to have .txt suffix
# c) archive name is derived from file name
#

sub _zipit {
    my $self = shift;
    my $opts = {};
#    $opts->{DATES} = $self->{DATES};
    $opts->{CACHED} = 1;

    my $from = GSI::DataX::GNC::GoldCard::Files::Export->existing();
    my $to   = GSI::DataX::GNC::GoldCard::Files::ZipOut->new($opts);

    my $status = 1;
    if (defined $from and defined $from->newest) {
	my $path = $from->newest->path;
	my $name = $from->{SET_NAME};

	my $zip  = Archive::Zip->new();
	my $cwd  = cwd();
	my $dir  = dirname($path);
	my $file = basename($path);
	(my $zipName = $file) =~ s/\.txt/.zip/;

	$self->verbose(1, "Zipping $name from $dir\n");
	$self->verbose(1, "\t$file\n");
	$self->verbose(1, "Into zip archive $zipName\n");

	chdir($dir) or warn "Failed to chdir to $dir: $!\n";
	$zip->addFile($file) or
	  warn "Can't add file $file to zip archive\n" and $status = 0;
	$zip->writeToFileNamed($zipName) and
	  warn "Can't create zip archive $zipName\n" and $status = 0;

	# Move it to the zipout directory.
	my ($order, $map) = $from->map_to($to);
	my $firstFrom	  = @$order[0];
	my $mappedTo	  = $map->{$firstFrom};
	my $connTo	  = $mappedTo->connect();
	my $connFrom	  = $firstFrom->connect();

	my $fromPath	=  $connFrom->full_path();
#	# hack! extracted file name based on archive name, but without
#	# the timestamp and with .txt instead of .zip
#	$fromPath	=~ s/_\d*_\d*\.zip/.txt/;
	my $toPath	=  $connTo->full_path();
	$toPath		=  dirname($toPath) . '/' . $zipName;

	$self->verbose(3, "move $zipName to $toPath\n");

	my $sts = move($zipName, $toPath);
	if (!$sts) {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error!  Failed to move GNC GoldCard zip file\n";
	}
	chdir($cwd) or warn "Return chdir failed to $cwd: $!\n";
    }
    else {
	$self->{ERROR} = 1;
	$self->{MSG} = "Error!  No GNC Gold Card Export files for archive\n";
	warn("\n!!! $self->{MSG}\n\n");
    }

    return $status;
}

1;
