#! /usr/bin/perl -w
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Tie::IxHash;
use P2P::pDonkey::Met ':server';

my (%servers, $nserv);
tie %servers, "Tie::IxHash";

warn "Usage: $0 <file>\n" unless @ARGV;
$ARGV[0] or $ARGV[0] = 'server.met';

$nserv = ReadServerMet($ARGV[0], \%servers);
PrintServerMet(\%servers);
print "Servers: $nserv\n";
#WriteServerMet('ss.met', \%servers);

