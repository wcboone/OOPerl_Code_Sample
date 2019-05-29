#!/usr/local/bin/perl -nw
#
# QAD utility to check email addresses in GNC customer feed export.
#
# Designed to work with the output from fmtExport.sh
#
# $Id: gncEmailCheck.pl,v 1.1 2007/01/19 23:15:19 donohuet Exp $

use strict;
use warnings;

our ($id, $email);
BEGIN {
    $id = $email = undef;
}

m/^GSI_BILL_TO_NBR/ and do {
    $id = $_;
};

m/^EMAIL_ADDRESS/ and do {
    $email = $_;
};

m/^GSI_REASON/ and do {
    if (m/^GSI_REASON.*E$/) {
	if (defined $id and defined $email) {
	    (my $em = $email) =~ s/^EMAIL_ADDRESS:  *//;
	    chomp $em;
	    if ($em eq '') {
		print "Invalid email: empty\n";
		print "\t${id}\t${email}\t$_\n";
	    }
	    elsif ($email !~ m/[@\.]/) {
		print "Invalid email: missing @ or .\n";
		print "\t${id}\t${email}\t$_\n";
	    }
	}
    }
    $id = $email = undef;
};

1;
