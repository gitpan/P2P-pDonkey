#! /usr/bin/perl -w
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use IO::Socket;
use Sys::Hostname;
use P2P::pDonkey::Meta qw( :tags makeMeta );
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::ServerMet ':all';
use P2P::pDonkey::Util ':all';
use Data::Hexdumper;

#use ServBase;

my ($debug, $dump) = (0, 0);
my $hostname = hostname();

my %servers;
my $nserv = ReadServerMet('ss.met', \%servers);
print "Servers: $nserv\n";

my $localport = 5000;

my $udpsock = new IO::Socket::INET(
        Proto => 'udp', 
        Reuse => 1, 
        LocalPort => $localport)
    || die "can't open udp socket: $@\n";

my $request = packUDPHeader() . packBody(PT_UDP_GETSERVERLIST, 
                                         unpack('L', gethostbyname($hostname)),
                                         $localport);
#my %searchq = (Type => ST_NAME, Value => 'met');
#my $request = packUDPHeader() . packBody(PT_UDP_SEARCHFILE, \%searchq);
#print hexdump(data => $request);

#RequestServList(unpack('L', gethostbyname('176.16.4.244')), 4661+4);
#RequestServList(unpack('L', gethostbyname('176.16.5.33')), 4661+4);
#for my $kk (0 .. 10) {
#    RequestServList(unpack('L', gethostbyname('176.16.4.244')), 4661+$kk);
#}
foreach my $meta (values %servers) {
    RequestServList($meta->{IP}{Value}, $meta->{Port}{Value});
}

$SIG{INT} = sub { 
    my $nserv = WriteServerMet('ss.met',  \%servers); 
    print "Written $nserv servers\n";
    exit;
};

my ($response, $peer);
while (defined($peer = $udpsock->recv($response, 20000, 0))) {
    my ($port, $addr) = sockaddr_in($peer);
    $addr = inet_ntoa($addr);
    
    my ($h, $pt, $len);
    if (length $response <= SZ_UDP_HEADER) {
        warn "$addr:$port: too small packet\n";
        next;
    }
    
    my $off = 0;
    if (!unpackUDPHeader($response, $off)) {
        warn "$addr:$port: incorrect header tag\n";
        next;
    }

    # unpack server list
    my @res = unpackBody(\$pt, $response, $off);
    if ($pt != PT_UDP_SERVERLIST) {
        warn "$addr:$port: got packet '", PacketTagName($pt), "'\n";
        next;
    }
    if (!@res) {
        warn "$addr:$port: incorrect packet data\n";
        next;
    }
    my ($sip, $sport, $addrl) = @res;

    # all ok, process server list
    my $nservnew = 0;
    while (@$addrl) {
        my ($meta);
        ($sip, $sport) = (shift @$addrl, shift, @$addrl);
        next if $meta = $servers{ip2addr($sip).":$sport"};
        $nservnew++;
        $servers{ip2addr($sip).":$sport"} = {
            Name => '',
            Description => '',
            IP => $sip,
            Port => $sport,
            Preference => 0
            };
        RequestServList($sip, $sport);
    }
    print "$addr:$port: $nservnew new servers\n";
    $nserv += $nservnew;
}
die "EXIT: $! ::: $@\n";
exit;

sub RequestServList {
    my ($portaddr, $ip, $port);
    while (@_) {
        $ip = shift;
        $port = shift;
        $portaddr = sockaddr_in($port+4, pack('L', $ip));
        $udpsock->send($request, 0, $portaddr)
            or die "can't send to ", ip2addr($ip), ":$port: $!\n";
        print "request to ", ip2addr($ip), ":$port\n";
    }
}
