#! /usr/bin/perl -w
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Tie::IxHash;
use Tie::RefHash;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Util ':all';
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::Met qw(ReadServerMet WriteServerMet);
use ServBase;

my ($debug, $dump) = (1, 0);

my $user = makeClientInfo(0, 4662, 'Muxer', 60);

my ($nserv, %servers);
$nserv = ReadServerMet('ss.met', \%servers);
#$servers{'176.16.4.244:4661'} = {IP => addr2ip('176.16.4.244'), Port => 4661};
print "Servers: $nserv\n";

my @procTable;
$procTable[PT_SERVERLIST]   = \&processServerList;

my $server = new ServBase(ProcTable => \@procTable,
                          OnConnect => \&OnConnect,
                          Dump => $dump);

my $IN;
$IN = IO::Handle->new_from_fd(fileno(STDIN), 'r');
$IN->blocking(0);
#$IN->autoflush(1);
$server->watch($IN);

$SIG{INT} = sub { 
    my $nserv = WriteServerMet('ss.met',  \%servers); 
    print "Written $nserv servers\n";
    exit;
};

foreach my $s (values %servers) {
    $server->Connect(ip2addr($s->{IP}{Value}), $s->{Port}{Value}) || warn "Connect: $!";;
}
#$server->Connect('176.16.4.244', 4661) || warn "Connect: $!";
$server->MainLoop() || die "Can't start server: $!\n";

exit;

sub OnConnect {
    my ($conn) = @_;
    $server->Queue($conn, PT_HELLO, $user);
    $server->Queue($conn, PT_GETSERVERLIST, '');
}

sub processServerList {
    my ($conn, $d) = @_;
    my ($ip, $port);

    my $snum = @$d/2;
    print "\tGot $snum servers:\n";

    while (@$d) {
        $ip   = shift @$d;
        $port = shift @$d;
        print "\t", ip2addr($ip), ":$port\n" if $debug;
        $servers{ip2addr($ip).":$port"} = [
            IP   => makeMeta(TT_IP, $ip),
            Port => makeMeta(TT_PORT, $port)
            ];
        $server->Connect(ip2addr($ip), $port) || warn "Connect: $!";
    }
    $server->Disconnect($conn->{Socket});
}
