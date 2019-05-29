#
# Check on the GNC GoldCard Import
#
# GNC creates and uploads the GNC GoldCard file weekly.  GSI usually receives
# it by Monday or Tuesday morning, but there is some variation in the GNC
# process and it could come later.  Email an alert to GNC and GSI if the file
# has not arrived by 10am Thursday.
#

#
# $Id: CheckImport.pm,v 1.1 2006/12/07 22:13:45 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::Mail::Sender;
use GSI::DataX::GNC::GoldCard::Files::Local;

use GSI::OptArg::ClassAttr {
    DATE	=> { MODIFY	=> 1,
		     DEFAULT	=> { START => '4 days', },	#? todo
		   },
};

sub checkimport {
    my $self = shift;

    $self->verbose(1, entrystamp('checkimport', __PACKAGE__));

    my $opts = {};
    $opts->{DATES} = $self->{DATES};

    my ($localSet, $localName, $localPath) = (undef, undef, undef);

    $localSet = GSI::DataX::GNC::GoldCard::Files::Local->existing($opts);
    if (!defined $localSet  or scalar(@{$localSet->files()}) == 0) {
	$self->{ERROR} = 1;
	$self->{MSG} = "Error!  No GNC Gold Card files found to import.\n";
	warn("\n!!! $self->{MSG}\n\n");
    }
    else {
	$localName = $localSet->{SET_NAME};
	$localPath = $localSet->newest()->{PATH};

	if (!defined $localPath or $localPath eq '') {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error! No \"$localName\" found to import.\n";
	    $self->verbose(1, "\n!!! $self->{MSG}\n\n");
	    warn("\n!!! $self->{MSG}\n\n");
	}
	else {
	    $self->verbose(1, "Using \"$localName\" file \"$localPath\"\n");
	}
    }

#ng
#    my $mailSig = $self->{MAIL_SIG};
#    $self->verbose(1, ">>> mailSig = ~$mailSig~\n");
#ng
#    my $mailSig1 = $self->{MAIL_SIG1};
#    $self->verbose(1, ">>> mailSig1 = ~$mailSig1~\n");
#    my $mailSig2 = $self->{MAIL_SIG2};
#    $self->verbose(1, ">>> mailSig2 = ~$mailSig2~\n");

    if ($self->{ERROR}) {
	my $mailTo   = $self->{MAIL_TO};
	my $mailFrom = $self->{MAIL_FROM};
	my $mailSubj = $self->{MAIL_IMPORT_SUBJECT};
	my $mailBody = $self->{MAIL_IMPORT_BODY};

#ng
#	my $s;
#	$mailSig =~ s/\\\$/\$/g;
#	my $sig = eval '$s = $mailSig;';
#	$self->verbose(1, ">>> sig = ~$sig~\n");
#ng
#	my $sig = "$mailSig1\n$mailFrom$mailSig2";
#	$self->verbose(1, ">>> sig = ~$sig~\n");

	my $to = join(', ', @$mailTo);
	$self->verbose(3, "\tTO:\t$to\n");
	$self->verbose(3, "\tFROM:\t$mailFrom\n");
	$self->verbose(3, "\tSUBJ:\t$mailSubj\n");
	$self->verbose(3, "\tBODY:\t$mailBody\n");

	# Email alert to GNC...
	$self->verbose(1, "CheckImport:  sending email alert.\n\n");
	GSI::Mail::Sender->send(TO	=> $mailTo,
				FROM	=> $mailFrom,
				SUBJECT	=> $mailSubj,
				BODY	=> $mailBody);

	# Email alert to GSI...
	my $mailToFeeds	  = $self->{MAIL_TO};
	my $mailSubjFeeds = "FW: " . $self->{MAIL_IMPORT_SUBJECT};
	my $mailBodyFeeds = $self->{MAIL_BODY_FEEDS};
	my $mailTime	  = localtime();
	my $origMesg	  =<< "xxENDxx";
-----Original Message-----
From: $mailFrom
Sent: $mailTime
To: $to
Subject: $mailSubj

xxENDxx
	$mailBodyFeeds .= $origMesg . $mailBody;
	GSI::Mail::Sender->send(TO	=> $mailToFeeds,
				FROM	=> $mailFrom,
				SUBJECT	=> $mailSubjFeeds,
				BODY	=> $mailBodyFeeds);
    }
    return 1;
}

1;
