#
# $Id: CommandLine.pm,v 1.1 2011/10/31 18:11:38 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog::CommandLine;
our $VERSION = 1.00;

use GSI::DataX::GNC::Catalog;
use GSI::DataX::GNC::Export::CommandLine;

our @ISA = qw(GSI::DataX::GNC::Catalog 
              GSI::DataX::GNC::Export::CommandLine);

sub ui_init 
{
    my $ui_class = shift;
}

sub ui_map_command_line
{
    my $ui_class = shift;
}

use GSI::OptArg::CommandLine
(
);

#
# Public Methods
#
sub check_command_line_opts
{
    return 1;
}

1;
