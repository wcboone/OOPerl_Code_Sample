#
# $Id: CommandLine.pm,v 1.2 2011/10/31 18:19:49 demij Exp $
#

use strict;

package GSI::DataX::GNC::Export::CommandLine;
our $VERSION = 1.00;

use GSI::DataX::ActionLoader::CommandLine;

our @ISA = qw(GSI::DataX::ActionLoader::CommandLine);

#use GSI::OptArg::Map::OptDef::Type::DateTimeRange;

my ($files, $create, $upload);
my ($local, $remote);
my $ls_mode;
#my ($start_date, $end_date, $date);

sub ui_init 
{
    my $ui_class = shift;

    $ui_class->_action_mirror(Files  => \$files,  Create => \$create,
                              Upload => \$upload);

    $ui_class->mirror('LOCAL',   \$local);
    $ui_class->mirror('REMOTE',  \$remote);
    $ui_class->mirror('LS_MODE', \$ls_mode);
}

sub ui_map_command_line
{
    my $ui_class = shift;
}

use GSI::OptArg::CommandLine
(
    "files|ls|dir!"             => \$files,
    "create|export!"            => \$create,
    "upload|send!"              => \$upload,
    "lsmode=s"                  => \$ls_mode,
    "local!"                    => \$local,
    "remote!"                   => \$remote,
);

#
# Public Methods
#
sub check_command_line_opts
{
    my $class   = shift;

    return 1;
}

1;
