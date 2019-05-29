#
# $Id: HackBillToNBR.pm,v 1.1 2009/07/10 18:08:25 wallacej Exp $
#
# Ticket 88312
#
#This is regarding PS 88312. The summary goes like this .
#
#Earlier GSI internal customer was 9 bytes long and it is being passed to 
#GNC customer data feed but the same customer in shipped orders feed was 10 
#bytes long (as GSI explicitly add extra byte to it). This causes mismatch b/w two feeds. 
#Now the solution which was proposed at that time was to strip extra byte from shipped 
#orders feed and that removed the mismatch b/w two feeds.
#
#At present, GSI consumed all its 9 bytes and started to generate actual 10 bytes long 
#customer (without adding extra byte), but code set up to drop the extra byte from 
#shipped orders feed is still in place so again the mismatch appears.
#
#

use strict;

package GSI::DataX::GNC::GoldCard::HackBillToNBR;
our $VERSION = 1.00;

use GSI::DataTranslate::Filter;
our @ISA = qw(GSI::DataTranslate::Filter);


sub filter
{
    my $self            = shift;
    my $row             = shift;

    my $bill_to_num     = $row->get_column('GSI_BILL_TO_NBR');
    my $mylength        = length($bill_to_num);
    my $mynum_len       = 0;


    if ($mylength < 10)
    {
     print "Change $bill_to_num to ";
     $bill_to_num =~ s/^(.*$)/2$1/;
     $mynum_len = 10 - ($mylength + 1);
     $bill_to_num = $bill_to_num * (10 ** $mynum_len);
     print "$bill_to_num\n";
     $row->add_or_update_column('GSI_BILL_TO_NBR', $bill_to_num);
    }


    return $row;
}

1;
