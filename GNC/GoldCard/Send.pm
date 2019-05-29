#
# $Id: Send.pm,v 1.3 2005/11/18 15:47:39 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataX::GNC::GoldCard::Files::Report;
use POSIX qw(strftime);
use GSI::DateTime::Convert;
use GSI::Mail::Sender;
use GSI::URL::PathToURL;

# Originally sent the Excel report file as an attachment, but to reduce
# mailbox size and avoid delivery problems (e.g. virus scans) now sends a
# URL reference to a file on the GSI intranet.
#
# For external delivery:
# a) OBM attaches the report and forwards,
# b) Implement two recipient lists: gsiMailTo and externalMailTo

sub send {
    my $self = shift;
    my $mailTo   = $self->{MAIL_TO};
    my $mailFrom = $self->{MAIL_FROM};
    my $ccTo     = $self->{CC_TO};
    my $bccTo    = $self->{BCC_TO};

    $self->verbose(1, "Entered 'send' (", __PACKAGE__, ")\n");
    $self->verbose(1, "Mail report to:\t", join(", ", @$mailTo), "\n");
    $self->verbose(1, "  CC report to:\t", join(", ", @$ccTo), "\n")
	if (defined($ccTo) and scalar(@$ccTo) > 0);
    $self->verbose(1, " BCC report to:\t", join(", ", @$bccTo), "\n")
	if (defined($bccTo) and scalar(@$bccTo) > 0);

    my $signature = <<"xxENDxx";
Please direct inquiries about this report to the DataFeeds Team at GSI Commerce.

--
$mailFrom
GSI Commerce, Inc.
http://www.gsicommerce.com

The information contained in this electronic mail transmission is intended only for the use of the individual or entity named in this transmission. If you are not the intended recipient of this transmission, you are hereby notified that any disclosure, copying or distribution of the contents of this transmission is strictly prohibited and that you should delete the contents of this transmission from your system immediately. Any comments or statements contained in this transmission do not necessarily reflect the views or position of GSI Commerce, Inc. or its subsidiaries and/or affiliates.

xxENDxx

    my $opts = {};
    $opts->{DATES} = $self->{DATES};

    my $error = $self->{ERROR};
    my $errorMsg = $self->{MSG};

    my $dbName		= $self->{DB_NAME};
    my $existingCount	= $self->{EXISTING_COUNT};
    my $insertCount	= $self->{INSERT_COUNT};
    my $deleteCount	= $self->{DELETE_COUNT};
    my $updateCount	= $self->{UPDATE_COUNT};

    my $tags = $self->effective_test_tags;
    if ($tags->{SEND}) {
	$insertCount = $deleteCount = $updateCount = 991234;
    }

    my $reportSet = GSI::DataX::GNC::GoldCard::Files::Report->existing($opts);
    my $newest = $reportSet->newest;
    my $reportPath;
    if (!defined($reportSet) or !defined($newest)) {
	$reportSet  = GSI::DataX::GNC::GoldCard::Files::Report->new();
	$reportPath = $reportSet->new_file->path() if (defined($reportSet));
    }
    else {
	$reportPath = $reportSet->newest->path();
    }
    my $reportName = $reportSet->{SET_NAME};
    $reportName  =~ s/\'//g;

    $self->verbose(3, "reportName = $reportName\n");
    $self->verbose(3, "reportPath = $reportPath\n");

    my $date = strftime("%Y%m%d", localtime());
    my $time = strftime("%H:%M", localtime());
    if (!$error) {
	# Assumes YYYYMMDDHHMMSS format in the report filename.
	$date = $time = $reportPath;
	$date =~ s#^.*/##;
	$date =~ s#\d{6}\..*$##;
	$time =~ s#^.*(\d\d)(\d\d)(\d\d)\..*#\1:\2#;
    }
    $date = date_time_convert($date, "%A %B %e, %Y");

    my $preamble1 = "$reportName for $date";
    my $preamble2 = "Loaded in the $dbName database at $time"
      if ($dbName !~ m/catman/i);
    my $subject	    = $reportName;
    my $attachments = undef;
    my $body;

    if ($error) {
	$self->verbose(1, "Sending Error report due to:\n");
	$self->verbose(1, "\t$errorMsg\n");
	$subject .= " -- Error!";
	$body  = <<"xxENDxx";
$preamble1
        $preamble2

The GNC GoldCard data were not updated due to an error:
    $errorMsg


$signature
xxENDxx
    }
    elsif ( (!defined($insertCount) or $insertCount == 0) and
	    (!defined($deleteCount) or $deleteCount == 0) and
	    (!defined($updateCount) or $updateCount == 0)) {
	$body = <<"xxENDxx";
$preamble1
        $preamble2

No changes were detected in the file received today.


$signature
xxENDxx
    }
    else {
#	$attachments = $reportPath;				# old
	my $reportURL = path_to_url($reportPath);		# new
	$self->verbose(3, "reportURL  = $reportURL\n");
	my $is = $insertCount == 1 ? '' : 's';
	my $ds = $deleteCount == 1 ? '' : 's';
	my $us = $updateCount == 1 ? '' : 's';
	$body = <<"xxENDxx";
$preamble1
        $preamble2

This Excel workbook
	$reportURL
contains these four worksheets:

    Existing	is the $existingCount current stores, before the latest master file from GNC is loaded.
    Additions	is the $insertCount new store$is to be added.
    Deletions	is the $deleteCount store$ds to be removed.
    Updates	is the $updateCount current store$us to be modified.


$signature
xxENDxx
    }

    $subject .= " ($dbName)" if ($dbName !~ m/catman/i);

    my $mailer =  GSI::Mail::Sender->send(
			FROM		=> $mailFrom,
			TO		=> $mailTo,
			CC		=> $ccTo,
# future, must enhance GSI::Mail::Sender
#			BCC		=> $bccTo,
			SUBJECT		=> $subject,
			BODY		=> $body,
			ATTACHMENTS	=> $attachments
					 );
    return 1;
}

1;
