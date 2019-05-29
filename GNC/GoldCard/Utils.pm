#
# $Id: Utils.pm,v 1.2 2005/12/06 22:38:27 donohuet Exp $
#

# perldoc at bottom...

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard;

use POSIX qw(strftime);

our $verboseLevel = GSI::Utils::Verbose->get_level();
our @ISA = qw(Exporter);
use vars qw($verboseLevel);
our @EXPORT = qw($verboseLevel);


### Return time in YYYY.MM.DD-hh:mm:ss format.
sub timestamp {
    return strftime("%Y/%m/%d-%T", localtime(time));
}

### Return standard subroutine entry message.
sub entrystamp {
    my $sub  = shift;
    my $pkg  = shift;
    return "\nEntered '$sub' ($pkg) at " . timestamp() . "\n";
}

### Return `undef' for an undefined value.
sub undefined {
    my $v = shift;
    return defined $v ? $v : 'undef';
}

### Return `yes' or `no' for a (boolean) value.
sub yesno {
    my $v = shift;
    return $v ? 'yes' : 'no';
}

### Dump a hash
# usage:
# $self->dumpHash("Brands", $self->brand_hash);
#
sub dumpHash {
    my $self		= shift;
    my $hashName	= shift;
    my $hashRef		= shift;

    my $tags = $self->effective_test_tags;
    (my $tagName = uc($hashName)) =~ s/\s*//g;
    (my $indent = $hashName) =~ s/^(\s*).*/$1/;
    if ($tagName =~ m/TAGS/ or $tags->{$tagName}) {
	print("$hashName: $hashRef\n");
	while (my ($k, $v) = each %$hashRef) {
	    $k .= "\t" if (length($k) < 4);
	    $k = $indent . $k;
#?	    (my $indent = $hashName) =~ s/(\s*).*/$1/;
	    print("    $k\t=> ", undefined($v), "\n");
	}
	print("\n");
    }
}


### Dump a hash, sorted.
# usage:
# $self->dumpHashSorted("Brands", $self->brand_hash);
#
sub dumpHashSorted {
    my $self		= shift;
    my $hashName	= shift;
    my $hashRef		= shift;

    my $tags = $self->effective_test_tags;
    (my $tagName = uc($hashName)) =~ s/\s*//g;
    (my $indent = $hashName) =~ s/^(\s*).*/$1/;
    if ($tagName =~ m/TAGS/ or $tags->{$tagName}) {
	print("$hashName: $hashRef\n");
	foreach my $k (sort keys %$hashRef) {
	    my $v = $hashRef->{$k};
	    $k .= "\t" if (length($k) < 4);
	    $k = $indent . $k;
#?	    (my $indent = $hashName) =~ s/(\s*).*/$1/;
	    print("    $k\t=> ", undefined($v), "\n");
	}
	print("\n");
    }
}


### Dump a hash of hashes, sorted.
# usage:
# $self->dumpHashofHashes("Products", "PID", $self->pid_hash);
#
sub dumpHashofHashes {
    my $self		= shift;
    my $hashName	= shift;
    my $primaryKeyName	= shift;
    my $hashRef		= shift;

    my $tags = $self->effective_test_tags;
    (my $tagName = uc($hashName)) =~ s/\s*//g;		#tryit #todo
    if ($tagName =~ m/TAGS/ or $tags->{$tagName}) {
	print("$hashName: $hashRef\n");
	while (my ($key, $h) = each %$hashRef) {
	    print(">>  $primaryKeyName $key\n");
	    foreach my $k (sort keys %$h) {
		my $v = defined $h->{$k} ? $h->{$k} : 'UNDEF';
		if (ref($v) eq 'HASH') {
		    $self->dumpHash("    $k", $v);
		}
		else {
		    $k .= "\t" if (length($k) < 4);
		    my $l = length($v);
		    substr($v, 60 - $l) = "..."
		      if (($k =~ m/descr/i or $k =~ m/name/i) and 60 < $l);
		    print("    $k\t=> ", undefined($v), "\n");
		}
	    }
	}
	print("\n");
    }
}

### Dump a hash of hashes, sorted.
# usage:
# $self->dumpHashofHashesSorted("Products", "PID", $self->pid_hash);
#
sub dumpHashofHashesSorted {
    my $self		= shift;
    my $hashName	= shift;
    my $primaryKeyName	= shift;
    my $hashRef		= shift;

    my $tags = $self->effective_test_tags;
    (my $tagName = uc($hashName)) =~ s/\s*//g;		#tryit #todo
    if ($tagName =~ m/TAGS/ or $tags->{$tagName}) {
	print("$hashName: $hashRef\n");
#	while (my ($key, $h) = each %$hashRef) {
	foreach my $key (sort keys %$hashRef) {
	    my $h = $hashRef->{$key};
	    print(">>  $primaryKeyName $key\n");
	    foreach my $k (sort keys %$h) {
		my $v = defined $h->{$k} ? $h->{$k} : 'UNDEF';
		if (ref($v) eq 'HASH') {
		    $self->dumpHash("    $k", $v);
		}
		else {
		    $k .= "\t" if (length($k) < 4);
		    my $l = length($v);
		    substr($v, 60 - $l) = "..."
		      if (($k =~ m/descr/i or $k =~ m/name/i) and 60 < $l);
		    print("    $k\t=> ", undefined($v), "\n");
		}
	    }
	}
	print("\n");
    }
}

### Dump a hash of arrays.
# usage:
# $self->dumpHashofArrays("???", "???", $self->???);
#
sub dumpHashofArrays {
    my $self		= shift;
    my $hashName	= shift;
    my $primaryKeyName	= shift;
    my $hashRef		= shift;
    my $sort		= shift;

    $sort = 0 if (!defined $sort or ($sort eq ''));
    # how to implement conditional sorting in foreach ...?		#todo

    my $tags = $self->effective_test_tags;
    (my $tagName = uc($hashName)) =~ s/\s*//g;		#tryit #todo
    if ($tagName =~ m/TAGS/ or $tags->{$tagName}) {
	print("$hashName: $hashRef\n");
	foreach my $k (keys %$hashRef) {
#error	    print(">>  $primaryKeyName $k => @{%$hashRef->{$k}}\n");	#todo
	    my $aref = $hashRef->{$k};
	    print(">>  $primaryKeyName $k => ", join(', ', @$aref), "\n"); #?
	}
	print("\n");
    }
}

1;


=head1 NAME

Utils - GNC Datafeed Utilities

=head1 SYNOPSIS

timestamp()

entrystamp()

undefined()

yesno()

dumpHash()

dumpHashofHashes()

dumpHashofArrays()

=head1 DESCRIPTION

timestamp returns a standard format timestamp

entrystamp returns a standard format function entry message

undefined returns the passed value else "undef" if not defined

yesno decodes a boolean to "yes" or "no"

dumpHash prints a hash.

dumpHashofHashes prints a hash of hashes.

dumpHashofArrays prints a hash of arrays.

=head1 EXAMPLE

=over 4

 $self->dumpHashofHashes("Products", "PID", \%hash);

=head1 SEE ALSO

=item *

Instead of a local implemention, investigate whether these might be best
as part of a GSI base package (or might even already exist elsewhere).

=item *

L<GSI::DataX::GSI::Base>

=head1 AUTHOR

Tom Donohue

=head1 REVISION

$Id: Utils.pm,v 1.2 2005/12/06 22:38:27 donohuet Exp $

=cut

