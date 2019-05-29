use strict;

package GSI::DataX::GNC::StoreLocator::CommandLine;
our $VERSION = 1.00;

use GSI::DataX::GNC::StoreLocator;
use GSI::DataX::GNC::Base::CommandLine;

our @ISA = qw(GSI::DataX::GNC::StoreLocator GSI::DataX::GNC::Base::CommandLine);

use GSI::Utils::Mirror qw(flags_mirror);

my ($downloaded );
my ($files, $remote, $download, $load, $overwrite);
my $check;
my %check_opts;
my @order_ids;

sub ui_init
{
    my $ui_class = shift;
    my $checks   = $ui_class->checks();
    $ui_class->_action_mirror(Files => \$files, 
                              Download => \$download,
                              Load => \$load,
                              Check => \$check);

    $ui_class->mirror('REMOTE',     \$remote);
    $ui_class->mirror('DOWNLOADED', \$downloaded);
    $ui_class->mirror('OVERWRITE',  \$overwrite);
    $ui_class->mirror('REMOTE', \$remote);

    flags_mirror($checks, Download => \$check_opts{download});
}

sub ui_map_command_line
{
    my $ui_class = shift;
}

use GSI::OptArg::CommandLine
(
    "overwrite|force!" => \$overwrite,
    "remote|ftp!"      => \$remote,
    "files!"           => \$files,
    "download!"        => \$download,
    "downloaded!"      => \$downloaded,
    "load!"            => \$load,
    "check=s"          => \%check_opts,
);

#
# Public Methods
#
sub check_command_line_opts
{
    my $class   = shift;

    if (scalar(%check_opts) > 0)
    {
        my $checks = $class->checks();
        my $flag;

        $check = 1;
        @{%{$checks}}{keys %$checks} = ($flag) x scalar(keys %$checks)
          if ($flag = $check_opts{all});
    }

    return 1;
}

1;
