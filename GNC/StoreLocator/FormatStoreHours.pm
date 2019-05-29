#!/usr/local/bin/perl
package GSI::DataX::GNC::StoreLocator::FormatStoreHours;

use strict;
use warnings;

use base qw{GSI::DataTranslate::Filter};


our $VERSION = sprintf( "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/ );

use GSI::OptArg::ClassAttr {};

use GSI::DataTranslate::Row;
use GSI::Utils::String;
use Data::Dumper;
my @days_list = qw{Monday Tuesday Wednesday Thursday Friday Saturday Sunday};
my %days_list;
foreach my $idx (0 .. $#days_list) {
  $days_list{substr($days_list[$idx],0,3)} = $idx;
}

sub _get_timezone_from
{
    my $time_withtimezone = shift;
    if (!defined $time_withtimezone) { return }

    my ($time,$timezone) = split /\-/, $time_withtimezone;

    if (!defined $timezone or !length($timezone)) {
      return;
    }

    $timezone =~ s/://g;

    return $timezone;
}

sub _get_time_from
{
    my $time_withtimezone = shift;
    if (!defined $time_withtimezone) { return }

    my ($time,$timezone) = split /\-/, $time_withtimezone;

    if (!defined $time or !length($time)) {
      return;
    }

    $time =~ s/://g;
    return substr($time,0,4);
}

sub gettime
{
    my $time = shift;
    my ($strhours,$minutes,$seconds,$timezone) = split /:/, $time;
    my $hours = int $strhours;
    my $timeofday = 'am';
    if ($hours >= 12) {
       $timeofday = 'pm';
       if ($hours > 12) {
          $hours = $hours - 12;
       }
    } elsif ($hours == 0) {
        #(00:00) Midnight is 12am not 0am
        $hours = 12;
    }

    return ($hours, $minutes, $timeofday);
}

sub buildtime
{
    my $start = shift;
    my $close = shift;
    my $timestring = '';

    if (defined $start and $start ne '') {
        my ($sthours, $stmins, $sttod) = gettime($start);
        my ($clhours, $clmins, $cltod) = gettime($close);
		if (($sthours == 0) && ($stmins == 0)) {
            $timestring = 'Closed';
        } else {
            # Note, a few stores open or close on minutes past the hour.
            # Include the minutes if not zero.
            if ($stmins == 0 and $clmins == 0) {
                $timestring = sprintf("%2.2s %s - %2.2s %s",
                                      $sthours,
                                      $sttod,
                                      $clhours,
                                      $cltod);
            } else {
                $timestring = sprintf("%2.2s:%2.2d %s - %2.2s:%2.2d %s",
                                      $sthours,
                                      $stmins,
                                      $sttod,
                                      $clhours,
                                      $clmins,
                                      $cltod);
            }
        }
    } else {
        $timestring = 'Closed';
    }
	
	return $timestring;
}

# CLOSING_TIME_SUN
# CLOSING_TIME_MON
# CLOSING_TIME_TUE
# CLOSING_TIME_WED
# CLOSING_TIME_THU
# CLOSING_TIME_FRI
# CLOSING_TIME_SAT
# OPENING_TIME_SUN
# OPENING_TIME_MON
# OPENING_TIME_TUE
# OPENING_TIME_WED
# OPENING_TIME_THU
# OPENING_TIME_FRI
# OPENING_TIME_SAT

sub _are_days_in_sequence {
  my ($days) = @_;

  CHECK_SEQ:
  for my $idx (0..$#{$days}) {

    # Skip 0
    if (!$idx) { next CHECK_SEQ };

    if ($days->[$idx - 1] + 1 != $days->[$idx]) {
      return 0;
    }

  }

  return 1;
}

sub _determine_hours
{
  my ($hourset, $days) = @_;

  my $days_in_set = scalar @$days;

  if ($days_in_set == 0) {
    return;
  }

  if ($days_in_set == 1) {
    return sprintf( "%-15.15s %s", $days_list[$days->[0]], $hourset );
  }

  if ($days_in_set == 2) {
   return sprintf( "%-15.15s %s",
            (join( ', ', map { substr($days_list[$_],0,3)
                          } @$days)),
             $hourset );
  }

  # For 3 or more days...

  # If the days are all sequential
  if ( _are_days_in_sequence($days)) {
   #if ($days_in_set > 2) {
   return sprintf( "%-15.15s %s",
            sprintf( "%3.3s-%3.3s",
              substr($days_list[$days->[0] ],0,3),
              substr($days_list[$days->[-1]],0,3)
              ),
            $hourset);
  }

  my @seq_list; my @return_hours;
  ALL_DAYS:
  foreach my $day (@$days) {

    if (!scalar(@seq_list)) {
      push @seq_list, $day;
      next ALL_DAYS;
    }

    # Does this day follow the last?
    if (($seq_list[-1] + 1) != $day) {
      # No...
      # Recursive call to self
      push @return_hours, _determine_hours( $hourset, \@seq_list );

        # Clear list.
        @seq_list = ();
    }

    push @seq_list, $day;
  }

  # Anything left to do?
  if (scalar(@seq_list)) {
        push @return_hours, _determine_hours( $hourset, \@seq_list );
  }

  return @return_hours;

}

sub filter
{
    my $self         = shift;
    my $row          = shift;


   my $close_count = 0;
   my $tab_char = '&nbsp';
   my %store_hours;

   my $day_idx = 0;
   foreach my $day (@days_list) {

    my $open_time  = "OPENING_TIME_" . substr(uc $day,0,3);
    my $close_time = "CLOSING_TIME_" . substr(uc $day,0,3);


    my $hours = buildtime($row->get_column($open_time), $row->get_column($close_time));

    push @{$store_hours{$hours}}, $day_idx;

    # NOTE: This changes the format of the time column after usage.
    $row->add_or_update_column($open_time,  _get_time_from($row->get_column($open_time)) );
    $row->add_or_update_column($close_time, _get_time_from($row->get_column($close_time)));

    $day_idx++;
   }

  my @hours;
  foreach my $hourset ( keys %store_hours ) {


    push @hours, _determine_hours( $hourset, \@{$store_hours{$hourset}}  );


  }
  # Perform a final sort to order days correctly.
  my $hours_text = join( '<br>',
                                sort {
                                      $days_list{substr($a,0,3)}
                                        <=>
                                      $days_list{substr($b,0,3)}
                                     } @hours
                   );
  # Determine if All the hours are closed.
  my $count_closed = grep { /Closed/i } @hours;
  if ($count_closed == (scalar @hours)) {
    # Per requirements, if closed and no phone this STORE_HOURS is empty.
    my $phone_number = $row->get_column(q{PHONE_NUMBER});
    if (defined $phone_number) {
      $hours_text = sprintf( q{Please contact the store<br> at %s for store hours},
        $phone_number );
    } else {
      $hours_text = '';
    }
  }
	
  $row->add_or_update_column('STORE_HOURS', $hours_text);
    # Using the value from Wednesday to determine the utc/gmt offset.
  $row->add_or_update_column('STORE_TIME_OFFSET', _get_timezone_from($row->get_column('OPENING_TIME_WED')));
  return $row;
}
1;
