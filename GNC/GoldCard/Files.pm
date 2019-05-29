#
# List GNC Gold Card FileSets.
#

#
# $Id: Files.pm,v 1.5 2006/12/07 22:20:11 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;
our $VERSION = 1.00;

use GSI::DataX::GNC::GoldCard::Files::RemoteIn;
use GSI::DataX::GNC::GoldCard::Files::ZipIn;
use GSI::DataX::GNC::GoldCard::Files::Local;
use GSI::DataX::GNC::GoldCard::Files::Export;
use GSI::DataX::GNC::GoldCard::Files::ZipOut;
use GSI::DataX::GNC::GoldCard::Files::RemoteOut;

sub files {
    my $self   = shift;

    my $opts   = {};
    $opts->{LS_MODE} = $self->{LS_MODE};
    $opts->{DATES} = $self->{DATES};

    if ($self->{REMOTE}) {
        my $iset = GSI::DataX::GNC::GoldCard::Files::RemoteIn->existing($opts);
        $iset->list();
        my $oset = GSI::DataX::GNC::GoldCard::Files::RemoteOut->existing($opts);
        $oset->list();
    }

    if ($self->{ZIPIN}) {
        my $set = GSI::DataX::GNC::GoldCard::Files::ZIPIN->existing($opts);
        $set->list();
    }

    if ($self->{LOCAL}) {
        my $set = GSI::DataX::GNC::GoldCard::Files::Local->existing($opts);
        $set->list();
    }

    if ($self->{EXPORT}) {
        my $set = GSI::DataX::GNC::GoldCard::Files::Export->existing($opts);
        $set->list();
    }

    if ($self->{ZIPOUT}) {
        my $set = GSI::DataX::GNC::GoldCard::Files::ZipOut->existing($opts);
        $set->list();
    }

    return 1;
}

1;
