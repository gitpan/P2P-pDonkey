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

warn "Usage: $0 <file>\n" unless @ARGV;
$ARGV[0] or $ARGV[0] = 'known.met';

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
    if (read($handle, $val, 1) != 1 || unpack('C',$val) != 0x0e) {
        carp "File '$fname' is not in \"met\" format\n";
        close($handle);
        return 0;
    }
    $buf = <$handle>;
    close $handle;
    $/ = $rs;

    my $l = unpackFileInfoList($buf, $off);
    foreach my $i (@$l) {
        printInfo($i);
    }
}
