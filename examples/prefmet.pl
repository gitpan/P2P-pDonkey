#! /usr/bin/perl -w
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Carp;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Util ':all';

warn "Usage: $0 <file>\n" unless @ARGV;
$ARGV[0] or $ARGV[0] = 'pref.met';

{
    my $fname = $ARGV[0];

    my ($val);
    
    my $buf;
    my $off = 0;

    my $handle;
    my $rs = $/;
    undef $/;
    open($handle, "<$fname") || (carp "Can't open `$fname': $!\n" && return 0);
    binmode($handle);
    $buf = <$handle>;
    close $handle;
    $/ = $rs;

    my ($ip, $port, $hash, $meta, $pref, $name, $m);
    ($ip, $port) = unpackAddr($buf, $off);
    print "Address: ", ip2addr($ip), ":$port\n";
    
    $hash = unpackHash($buf, $off);
    print "Hash: $hash\n";
    
    $meta = unpackMetaListU($buf, $off);
    print "Meta:\n";
    while (($name, $m) = each %$meta) {
        print "\t$name: $m->{Value}\n";
    }
    
    $pref = unpackMetaListU($buf, $off);
    print "Preferences:\n";
    while (($name, $m) = each %$pref) {
        print "\t$name: $m->{Value}\n";
    }
}
