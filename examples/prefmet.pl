#! /usr/bin/perl -w
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use P2P::pDonkey::Met ':pref';

warn "Usage: $0 <file>\n" unless @ARGV;
$ARGV[0] or $ARGV[0] = 'pref.met';

my $p = readPrefMet($ARGV[0]);
if ($p) {
    printPrefMet($p);
} else {
    print "$ARGV[0] is not in pref.met format\n";
}
