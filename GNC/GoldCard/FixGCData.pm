#
# $Id: FixGCData.pm,v 1.2 2005/11/09 17:42:04 donohuet Exp $
#

# This is copied from Ace::HHC::FixHHCData and may not be needed for GNC

package GSI::DataX::GNC::GoldCard::FixGCData;

use GSI::DataTranslate::Filter;
use vars qw(@ISA);

@ISA = qw(GSI::DataTranslate::Filter);

use GSI::OptArg::ClassAttr {};

use GSI::DataTranslate::Row;
use GSI::Utils::String;
use Lingua::EN::NameParse;
use GSI::Tie::Stat;

# optional configuration arguments
my %args =
(
      force_case      => 0,
      auto_clean      => 1,
      lc_prefix       => 0,
      initials        => 2,
      allow_reversed  => 1,
      joint_names     => 1,
      extended_titles => 1
);
my $testname = new Lingua::EN::NameParse(%args);

sub filter
{
    my $self         = shift;
    my $row          = shift;
    my $phone    = $row->get_column('phone_day');
    my $fullname = $row->get_column('full_name');
    my $dateadd  = $row->get_column('date_added');
    my $timeadd  = $row->get_column('time_added');
    my $op_code  = $row->get_column('operation_code');
    my $fname    = '';
    my $lname    = '';
    my $dtadd, $repl_type;
 
    $phone =~ s/\-//gi;
    $phone =~ s/\(//gi;
    $phone =~ s/\)//gi;
    $phone =~ s/ +//gi;

    my $error = $testname->parse($fullname);
#    if ($error == 0) {
    my %props = $testname->properties;
    my $numflag = $props{number};
    if (defined($numflag)) {
        my %names = $testname->components;
        $fname = $names{given_name_1} . " " . $names{middle_name} . $names{initials_1};
        $lname = $names{surname_1};

#    print "initials_1 is " . $names{initials_1} . "\n";
#    print "initials_2 is " . $names{initials_2} . "\n";
#    print "conjunction_1 is " . $names{conjunction_1} . "\n";
#    print "conjunction_2 is " . $names{conjunction_2} . "\n";
#    print "surname_2 is " . $names{surname_2} . "\n";
    }

#        my %props = $testname->properties;
    my $non_matching = $props{non_matching};
    if ($non_matching ne '') {
        print "non_matching is " . $non_matching . "\n";
        my $first = '';
        my $last = '';
        if ($non_matching =~ m/\s+/) {
            ($first, $last) = ($non_matching =~ /(.*)(\s+.*)/);
        } else {
            $first = $non_matching;
        } 
        if (defined($lname)) {
            $fname = $fname . " " . $lname;
        }
        if ($last ne '') {
            $fname = $fname . " " . $first;
            $lname = $last;
        } else {
            $lname = $first;
        }
    }
    $fname =~ s/^\s+//;
    $lname =~ s/^\s+//; 
    $processerr = 0;

    $dtadd = $dateadd . " " . $timeadd;

    if ($op_code eq 'A') {
        $repl_type = 1;
    } elsif ($op_code eq 'C') {
        $repl_type = 2;
    } elsif ($op_code eq 'D') {
        $repl_type = 3;
    } else {
        $repl_type = undef;
    }

    $row->update_column('phone_day', $phone);
    $row->add_column('first_name', $fname);
    $row->add_column('last_name', $lname);
    $row->add_column('datetime_added', $dtadd);
    $row->add_column('repl_type', $repl_type);

    if ($processerr == 0 ) {
        $row->add_column('error', 'false');
    } else {
        print "error!\n";
        $row->add_column('error', 'true');
    }

    return $row;
}
1;
