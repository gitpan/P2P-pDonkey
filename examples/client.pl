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
use P2P::pDonkey::Util;
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::Met qw(ReadServerMet WriteServerMet);
use ServBase;

my ($debug, $dump) = (1, 1);

# server configuration
my $incomingport = 4665;
my $maxClients = 100;
my $user = makeClientInfo(0, 4662, 'Muxer', 60);

my ($serverip, $serverport);

my ($nserv, %servers);
$nserv = ReadServerMet('ss.met', \%servers);
print "Servers: $nserv\n";
my $shared = makeFileInfoList('.');
my ($saddr, $port) = ('klon', 4661);

my @procTable;
$procTable[PT_HELLO]        = \&processHello;
$procTable[PT_HELLOANSWER]  = \&processHelloAnswer;
$procTable[PT_IDCHANGE]     = \&processIDChange;
$procTable[PT_SERVERMESSAGE]= \&processServerMessage;
$procTable[PT_SERVERSTATUS] = \&processServerStatus;
$procTable[PT_SERVERLIST]   = \&processServerList;
$procTable[PT_SERVERINFO] = \&processServerInfo;
$procTable[PT_SEARCHFILERES]= \&processSearchFileAnswer;

my $server = new ServBase(Port => $incomingport, 
                          MaxClients => $maxClients, 
                          ProcTable => \@procTable,
                          OnConnect => \&OnConnect,
#                          OnDisconnect => \&OnDisconnect,
#                          OnDisconnect => \&RemoveShared,
                          CanReadHook => \&checkIN,
                          Dump => 1,
                          nUsers => 0,
                          nFiles => 0);

my $IN;
$IN = IO::Handle->new_from_fd(fileno(STDIN), 'r');
$IN->blocking(0);
#$IN->autoflush(1);
$server->watch($IN);

$server->Connect($saddr, $port) || warn "Connect: $!";;
$server->MainLoop() || die "Can't start server: $!\n";

exit;

sub OnConnect {
    my ($conn) = @_;
    if ($conn->{Client}) {
        $user->{ServerIP} = $serverip;
        $user->{ServerPort} = $serverport;
        $server->Queue($conn, PT_HELLO, $user);
        printInfo($user);
        delete $user->{ServerIP};
    } else {
        $serverip   = $conn->{IP};
        $serverport = $conn->{Port};
        $server->Queue($conn, PT_HELLO, $user);
        printInfo($user);
    }
}

sub processHello {
    my ($conn, $d) = @_;
    printInfo($d);
    $user->{ServerIP} = $serverip;
    $user->{ServerPort} = $serverport;
    $server->Queue($conn, PT_HELLOANSWER, $user);
    printInfo($user);
    delete $user->{ServerIP};
}

sub processHelloAnswer {
    my ($conn, $d) = @_;
    printInfo($d);
}

sub processIDChange {
    my ($conn, $id) = @_;

    $user->{IP} = $id;
    print "\tnew ClientID: $id\n";

    foreach my $info (@$shared) {
        $info->{IP}   = $user->{IP};
        $info->{Port} = $user->{Port};
    }
    
    $server->Queue($conn, PT_GETSERVERLIST);
    $server->Queue($conn, PT_OFFERFILES, $shared);
}

sub processServerMessage {
    my (undef, $msg) = @_;
    print "$msg\n";
}

sub processServerStatus {
    my (undef, $users, $files) = @_;
    print "\tUsers: $users, Files: $files\n";
}

sub processServerList {
    my (undef, $d) = @_;

    my $snum = @$d/2;
    print "\tGot $snum servers:\n";
    for (my $i = 0; $i < $snum; $i++) {
        my ($ip, $port);
        $ip   = shift @$d;
        $port = shift @$d;
        print "\t", ip2addr($ip), ":$port\n" if $debug;
    }
}

sub processServerInfo {
    my (undef, $info) = @_;
    printInfo($info, 1);
}

sub processSearchFileAnswer {
    my (undef, $d) = @_;
    
    foreach my $res (@$d) {
        printInfo($res, 0);
    }
}

my $conn;
sub checkIN {
    my ($h) = @_;

    return if $h != $IN;

    my $cmd = $IN->getline;

    SWITCH: {
        if (!defined $cmd || $cmd =~ /^(q|quit)$/) {
#            WriteServerMet('ss.met', \%servers);
            exit;
        }
        
        if ($cmd =~ /^(s|search)\s+(.*)\s+(-(\W+))?$/) {
            my ($req, $ft) = ($2, $4);
            $server->Queue(undef, PT_SEARCHFILE, {Type => ST_NAME, Value => $req});
            last SWITCH;
        }

        if ($cmd =~ /^c ([^:]*):(\d*)$/) {
            $server->Connect($1, $2) || warn "Connect: $!";;
            last SWITCH;
        }

        if ($cmd =~ /^cc ([^:]*):(\d*)$/) {
            my $conn;
            $conn = $server->Connect($1, $2) or warn "Connect: $!";;
            $conn->{Client} = 1;
            last SWITCH;
        }

        if ($cmd =~ /^vf$/) {
            $server->Queue(undef, PT_VIEWFILES, '');
            last SWITCH;
        }
        
        if ($cmd =~ /^\?$/) {
            print <<END;
Commands:
    c  IP:Port      Connect to server
    cc IP:Port      Connect to client
    vf              View files of peer clients
    s  String       Search files by name
    q               Quit
END
            last SWITCH;
        }
        
        print "Unknown command\n";
    }
    #    my $cmd = $term->readline($prompt);
    #    defined($cmd) || exit;
    return 1;
}

