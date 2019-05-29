######################################################################

# original send -- emails excel file as attachemnt...
sub original_send {
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
mailto: $mailFrom
GSI Commerce, Inc.
http://www.gsicommerce.com

The information contained in this electronic mail transmission is intended only for the use of the individual or entity named in this transmission. If you are not the intended recipient of this transmission, you are hereby notified that any disclosure, copying or distribution of the contents of this transmission is strictly prohibited and that you should delete the contents of this transmission from your system immediately. Any comments or statements contained in this transmission do not necessarily reflect the views or position of GSI Commerce, Inc. or its subsidiaries and/or affiliates.

xxENDxx

    my $opts = {};
    $opts->{DATES} = $self->{DATES};

    my $error = $self->{ERROR};
    my $errorMsg = $self->{MSG};

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

    $self->verbose(3, "reportName = $reportName\n");
    $self->verbose(3, "reportPath = $reportPath\n");

    my $date = strftime("%Y%m%d", localtime());
    if (!$error) {
	# Assumes YYYYMMDDHHMMSS template in the file name generation, and
	# strips off the HHMMSS
	$date = $reportPath;
	$date =~ s#^.*/##;
	$date =~ s#......\..*$##;
    }
    $date = date_time_convert($date, "%A %B %e, %Y");

    $reportName  =~ s/\'//g;
    my $preamble	= "$reportName for $date";
    my $subject		= $reportName;
    my $attachments	= $reportPath;
    my $body		= <<"xxENDxx";
$preamble

The attached Excel workbook contains these four worksheets:

    'Existing' is the current table, before the latest master file from GNC is loaded.

    'Additions' is the new stores to be added.

    'Deletions' is the stores to be removed.

    'Updates' is the stores to be modified.



$signature
xxENDxx

    my $error = $self->{ERROR};
    my $errorMsg = $self->{MSG};
    if ($error) {
	$self->verbose(1, "Sending Error report due to:\n");
	$self->verbose(1, "\t$errorMsg\n");
	$subject	.= " -- Error!";
	$attachments	 = undef;
	$body		 = <<"xxENDxx";
$preamble

The GNC Store Locations were not updated due to an error:
    $errorMsg


$signature
xxENDxx
    }

    my $dbName = $self->{DB_NAME};
    $subject .= " ($dbName)" if ($dbName !~ m/catman/i);

    my $mailer =  GSI::Mail::Sender->send(
			FROM		=> $mailFrom,
			TO		=> $mailTo,
			CC		=> $ccTo,
# unsupported option, need to enhance Mail::Sender
#			BCC		=> $bccTo,
			SUBJECT		=> $subject,
			BODY		=> $body,
			ATTACHMENTS	=> $attachments
					 );
    return 1;
}
