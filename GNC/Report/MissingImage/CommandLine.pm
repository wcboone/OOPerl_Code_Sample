
use strict;
use warnings;

package GSI::DataX::GNC::Report::MissingImage::CommandLine;
our $VERSION = 1.00;

#use GSI::DataX::GNC::Report;
#use GSI::DataX::GNC::Import::CommandLine;

#our @ISA = qw(GSI::DataX::GNC::Import::CommandLine);
#our @ISA = qw(GSI::DataX::GNC::Report GSI::DataX::GNC::Import::CommandLine);

warn "Loaded ", __PACKAGE__,"\n" if (GSI::Utils::Verbose->get_level() > 2);

use GSI::Utils::Mirror qw(flags_mirror);

my $db_name;
my ($files, $create, $upload);
my ($store,@element_type);

use GSI::OptArg::CommandLine
(
    "create!"            => \$create,
    "upload|send!"              => \$upload,
    #"db|database|db_name=s"    => \$db_name,
    "store=s"                   => \$store,
    "element_type=s"            => \@element_type,
);

sub ui_init
{
    my $ui_class = shift;
    $ui_class->_action_mirror(Files  => \$files,  Create => \$create,
                              Upload => \$upload);
    #$ui_class->mirror('DB_NAME',  \$db_name);
    #$ui_class->mirror('ELEMENT_TYPE' =>        \@element_type);
}

sub ui_map_command_line
{
    my $ui_class = shift;

    $ui_class->store($store) if (defined($store));
    $ui_class->element_type(\@element_type) if (scalar(@element_type)>0);
}

#
# Public Methods
#
sub check_command_line_opts
{
    return 1;
}

1;

