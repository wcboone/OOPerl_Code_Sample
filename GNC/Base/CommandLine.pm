#
# $Id: CommandLine.pm,v 1.3 2005/11/15 21:27:34 donohuet Exp $
#

use strict;

package GSI::DataX::GNC::Base::CommandLine;
our $VERSION = 1.00;

use GSI::DataX::UI::CommandLine;
our @ISA = qw(GSI::DataX::UI::CommandLine);

use GSI::DataTranslate::CommandLine;
use GSI::OptArg::Map::OptDef::Type::DateTimeRange;

my ($start_date, $end_date, $date);
my $db_name;

sub ui_init
{
    my $ui_class = shift;
    $ui_class->mirror('DB_NAME',        \$db_name);
}

sub ui_map_command_line
{
    my $ui_class = shift;

    my $dates = GSI::OptArg::Map::OptDef::Type::DateTimeRange::Object->
                command_line_value($start_date, $end_date, $date);

    $ui_class->dates($dates) if (defined($dates));

    $ui_class->database($db_name) if (defined($db_name));

}

use GSI::OptArg::CommandLine
(
    "date=s"                       => \$date,
    "start|startdate=s"            => \$start_date,
    "end|enddate=s"                => \$end_date,
    "db|dbname|db_name|database=s" => \$db_name,
);

1;
