#
# Check on the GNC GoldCard Export
#
# GSI creates and uploads the file usually Monday or Tuesday morning, but there is
# some variation in their process and it could come later.  Email an
# alert to GSI and GNC if it has not arrived by 10am Thursday.
#

#
# Check on the GNC Customer Export
#
# GSI creates and uploads the GNC Customer file daily.  Email an alert to GSI
# and GNC if the file does not exist by 10am daily.
#


#
# $Id: CheckExport.pm,v 1.1 2006/12/07 22:13:45 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::Mail::Sender;
use GSI::DataX::GNC::GoldCard::Files::Export;
#use GSI::DataX::GNC::GoldCard::Files::RemoteOut; # check ftp site instead? #todo

use GSI::OptArg::ClassAttr {
    DATE	=> { MODIFY	=> 1,
		     DEFAULT	=> { START => '4 days', },	#? todo
		   },
};

sub checkexport {
    my $self	 = shift;

    $self->verbose(1, entrystamp('checkexport', __PACKAGE__));

    my $opts = {};
    $opts->{DATES} = $self->{DATES};

    my ($exportSet, $exportName, $exportPath) = (undef, undef, undef);

    $exportSet = GSI::DataX::GNC::GoldCard::Files::Export->existing($opts);
    if (!defined $exportSet  or scalar(@{$exportSet->files()}) == 0) {
	$self->{ERROR} = 1;
	$self->{MSG} = "Error!  No GNC Gold Card files found to export.\n";
	warn("\n!!! $self->{MSG}\n\n");
    }
    else {
	$exportName = $exportSet->{SET_NAME};
	$exportPath = $exportSet->newest()->{PATH};

	if (!defined $exportPath or $exportPath eq '') {
	    $self->{ERROR} = 1;
	    $self->{MSG} = "Error! No \"$exportName\" found to export.\n";
	    $self->verbose(1, "\n!!! $self->{MSG}\n\n");
	    warn("\n!!! $self->{MSG}\n\n");
	}
	else {
	    $self->verbose(1, "Using \"$exportName\" file \"$exportPath\"\n");
	}
    }

    if ($self->{ERROR}) {
	my $mailTo   = $self->{MAIL_TO};
	my $mailFrom = $self->{MAIL_FROM};
	my $mailSubj = $self->{MAIL_EXPORT_SUBJECT};
	my $mailBody = $self->{MAIL_EXPORT_BODY};

	GSI::Mail::Sender->send(TO	=> $mailTo,
				FROM	=> $mailFrom,
				SUBJECT	=> $mailSubj,
				BODY	=> $mailBody);
    }
    return 1;
}

1;
