#
# $Id: CommandLine.pm,v 1.2 2005/12/16 22:30:40 sells Exp $
#

use strict;

package GSI::DataX::GNC::Import::CommandLine;
our $VERSION = 1.00;

use GSI::DataX::GNC::Base::CommandLine;
our @ISA = qw(GSI::DataX::GNC::Base::CommandLine);

use GSI::DataTranslate::CommandLine;

my ($files, $download, $import, $load, $refresh, $testload, $subload, $update);
my ($local, $remote);

sub ui_init
{
    my $ui_class = shift;

    $ui_class->_action_mirror(Files   => \$files,  Download => \$download, 
                              Import  => \$import, Load => \$load,
                              SubLoad => \$subload, Update => \$update,
                              Refresh => \$refresh, TestLoad => \$testload);

    $ui_class->mirror('LOCAL',  \$local);
    $ui_class->mirror('REMOTE', \$remote);
}

sub ui_map_command_line
{
    my $ui_class = shift;
}

use GSI::OptArg::CommandLine
(
    "files|ls|dir!"               => \$files,
    "import!"                     => \$import,
    "load!"                       => \$load,
    "testload!"                   => \$testload,
    "subload!"                    => \$subload,
    "update!"                     => \$update,
    "refresh!"                    => \$refresh,
    "download|receive|get|pull!"  => \$download,
    "local|created!"              => \$local,
    "remote|ftp!"                 => \$remote,
);

1;
