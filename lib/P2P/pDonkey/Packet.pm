# P2P::pDonkey::Packet.pm
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Packet;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    PacketTagName
    packBody unpackBody
    packUDPHeader unpackUDPHeader
    packTCPHeader unpackTCPHeader

    SZ_UDP_HEADER
    SZ_TCP_HEADER

    PT_HEADER
    PT_HELLO
    PT_HELLOSERVER
    PT_HELLOCLIENT
    PT_BADPROTOCOL
    PT_GETSERVERLIST
    PT_OFFERFILES
    PT_SEARCHFILE
    PT_GETSOURCES
    PT_SEARCHUSER
    PT_IPREQUEST
    PT_MORERESULTS
    PT_SERVERLIST
    PT_SEARCHFILERES
    PT_SERVERSTATUS
    PT_IPREQUESTANS
    PT_IPREQUESTFAIL
    PT_SERVERMESSAGE
    PT_IDCHANGE
    PT_SERVERINFO
    PT_FOUNDSOURCES
    PT_SEARCHUSERRES
    PT_SENDINGPART
    PT_REQUESTPARTS
    PT_NOSUCHFILE
    PT_ENDOFOWNLOAD
    PT_VIEWFILES
    PT_VIEWFILESANS
    PT_HELLOANSWER
    PT_NEWCLIENTID
    PT_MESSAGE
    PT_FILESTATUSREQ
    PT_FILESTATUS
    PT_HASHSETREQUEST
    PT_HASHSETANSWER
    PT_UPLOADREQUEST
    PT_UPLOADACCEPT
    PT_CANCELTRANSFER
    PT_OUTOFPARTS
    PT_FILEREQUEST
    PT_FILEREQANSWER
    PT_UDP_SERVERSTATUSREQ
    PT_UDP_SERVERSTATUS
    PT_UDP_SEARCHFILE
    PT_UDP_SEARCHFILERES
    PT_UDP_GETSOURCES
    PT_UDP_FOUNDSOURCES
    PT_UDP_CALLBACKREQUEST
    PT_UDP_GETSERVERLIST
    PT_UDP_SERVERLIST
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

use Carp;
use P2P::pDonkey::Meta ':all';

use constant SZ_UDP_HEADER          => 1;       # 1 - header marker
use constant SZ_TCP_HEADER          => 5;       # 1 - header marker, 4 - packet length
# --- packet types
use constant PT_HEADER              => 0xe3;
use constant PT_HELLO               => 0x01;    # FIXME!!! 2 hello packets!!!
use constant PT_HELLOSERVER         => 0x01;
use constant PT_HELLOCLIENT         => 0x01;
use constant PT_BADPROTOCOL         => 0x05;
# client <-> server
use constant PT_GETSERVERLIST       => 0x14;
use constant PT_OFFERFILES          => 0x15;
use constant PT_SEARCHFILE          => 0x16;
use constant PT_GETSOURCES          => 0x19;
use constant PT_SEARCHUSER          => 0x1a;
use constant PT_IPREQUEST           => 0x1c;
use constant PT_MORERESULTS         => 0x21;
use constant PT_SERVERLIST          => 0x32;
use constant PT_SEARCHFILERES       => 0x33;
use constant PT_SERVERSTATUS        => 0x34;
use constant PT_IPREQUESTANS        => 0x35;
use constant PT_IPREQUESTFAIL       => 0x36;
use constant PT_SERVERMESSAGE       => 0x38;
use constant PT_IDCHANGE            => 0x40;
use constant PT_SERVERINFO          => 0x41;
use constant PT_FOUNDSOURCES        => 0x42;
use constant PT_SEARCHUSERRES       => 0x43;
# client <-> client
use constant PT_SENDINGPART         => 0x46;
use constant PT_REQUESTPARTS        => 0x47;
use constant PT_NOSUCHFILE          => 0x48;
use constant PT_ENDOFOWNLOAD        => 0x49;
use constant PT_VIEWFILES           => 0x4a;
use constant PT_VIEWFILESANS        => 0x4b;
use constant PT_HELLOANSWER         => 0x4c;
use constant PT_NEWCLIENTID         => 0x4d;
use constant PT_MESSAGE             => 0x4e;
use constant PT_FILESTATUSREQ       => 0x4f;
use constant PT_FILESTATUS          => 0x50;
use constant PT_HASHSETREQUEST      => 0x51;
use constant PT_HASHSETANSWER       => 0x52;
use constant PT_UPLOADREQUEST       => 0x54;
use constant PT_UPLOADACCEPT        => 0x55;
use constant PT_CANCELTRANSFER      => 0x56;
use constant PT_OUTOFPARTS          => 0x57;
use constant PT_FILEREQUEST         => 0x58;
use constant PT_FILEREQANSWER       => 0x59;
# client <-> UDP server
use constant PT_UDP_SERVERSTATUSREQ => 0x96;
use constant PT_UDP_SERVERSTATUS    => 0x97;
use constant PT_UDP_SEARCHFILE      => 0x98;
use constant PT_UDP_SEARCHFILERES   => 0x99;
use constant PT_UDP_GETSOURCES      => 0x9a;
use constant PT_UDP_FOUNDSOURCES    => 0x9b;
use constant PT_UDP_CALLBACKREQUEST => 0x9c;
use constant PT_UDP_GETSERVERLIST   => 0xa0;
use constant PT_UDP_SERVERLIST      => 0xa1;

my (@PacketTagName, @packTable, @unpackTable);

sub PacketTagName {
    return $PacketTagName[$_[0]];
}

# empty body
my $packEmpty = sub {
    return '';
};
my $unpackEmpty = sub {
    return 1;
};

sub unpackBody {
    my ($pt) = shift;
    defined($$pt = &unpackB) or return;
    my $f = $unpackTable[$$pt];
    defined($f) 
        or carp("Don't know how to unpack " . sprintf("0x%x",$$pt) . " packets\n")
           && return;
    return &$f;
}
sub packBody {
    my ($pt) = shift;
    my $f = $packTable[$pt];
    $f or confess "Don't know how to pack ".sprintf("0x%x",$pt)." packets\n";
    return pack('Ca*', $pt, &$f);
}

sub unpackUDPHeader {
    &unpackB == PT_HEADER or return;
    return 1;
}
sub packUDPHeader {
    return pack('C', PT_HEADER);
}

sub unpackTCPHeader {
    my $len;
    &unpackB == PT_HEADER or return;
    defined($len = &unpackD) or return;
    return $len;
}
sub packTCPHeader {
    return pack('CL', PT_HEADER, @_);
}

# -------------------------------------------------------------------
$PacketTagName[PT_HEADER]           = 'Header';
# -------------------------------------------------------------------
$PacketTagName[PT_HELLO]            = 'Hello';
#$unpackTable[PT_HELLO]              = \&unpackInfo;
#$packTable[PT_HELLO]                = \&packInfo;
$unpackTable[PT_HELLO]              = sub {
    my ($d, $hmm);
    defined($hmm = unpack("x$_[1] C", $_[0])) or return;
    if ($hmm == PT_HELLOCLIENT) {
        my $old_off = $_[1]++;
        defined($d = &unpackInfo) 
            && defined($d->{ServerIP} = &unpackD)
            && defined($d->{ServerPort} = &unpackW)
            && return $d;
        # failed, try Hello server
        $_[1] = $old_off;
    }
    return &unpackInfo;
};
$packTable[PT_HELLO]                = sub {
    my ($d) = @_;
    return $d->{ServerIP} 
           ? packB(0x10) 
               . &packInfo
               . packAddr($d->{ServerIP}, $d->{ServerPort})
           : &packInfo;
};
# -------------------------------------------------------------------
$PacketTagName[PT_BADPROTOCOL]      = 'Bad protocol';
$unpackTable[PT_BADPROTOCOL]        = $unpackEmpty;
$packTable[PT_BADPROTOCOL]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_GETSERVERLIST]    = 'Get server list';
$unpackTable[PT_GETSERVERLIST]      = $unpackEmpty;
$packTable[PT_GETSERVERLIST]        = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_OFFERFILES]       = 'Offer files';
$unpackTable[PT_OFFERFILES]         = \&unpackInfoList;
$packTable[PT_OFFERFILES]           = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHFILE]       = 'Search file';
$unpackTable[PT_SEARCHFILE]         = \&unpackSearchQuery;
$packTable[PT_SEARCHFILE]           = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_GETSOURCES]       = 'Get sources';
$unpackTable[PT_GETSOURCES]         = \&unpackHash;
$packTable[PT_GETSOURCES]           = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHUSER]       = 'Search user';
$unpackTable[PT_SEARCHUSER]         = \&unpackSearchQuery;
$packTable[PT_SEARCHUSER]           = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_IPREQUEST]        = 'IP(Callback?) request';
$unpackTable[PT_IPREQUEST]          = \&unpackD;
$packTable[PT_IPREQUEST]            = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_MORERESULTS]      = 'More results';
$unpackTable[PT_MORERESULTS]        = $unpackEmpty;
$packTable[PT_MORERESULTS]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERLIST]       = 'Server list';
$unpackTable[PT_SERVERLIST]         = \&unpackAddrList;
$packTable[PT_SERVERLIST]           = \&packAddrList;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHFILERES]    = 'Search file results';
$unpackTable[PT_SEARCHFILERES]      = sub {
    my ($res);
    defined($res = &unpackInfoList) or return;
    &unpackB; # FIXME
    return $res;
};
$packTable[PT_SEARCHFILERES]        = sub {
    return &packInfoList . packB(0);
};
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERSTATUS]     = 'Server status';
$unpackTable[PT_SERVERSTATUS]       = sub {
    my ($users, $files);
    defined($users = &unpackD) or return;
    defined($files = &unpackD) or return;
#    return {Users => $users, Files => $files};
    return ($users, $files);
};
$packTable[PT_SERVERSTATUS]         = sub {
#    my ($d) = @_;
#    return pack('LL', $d->{Users}, $d->{Files});
    return pack('LL', @_);
};
# -------------------------------------------------------------------
$PacketTagName[PT_IPREQUESTANS]     = 'IP request answer';
$unpackTable[PT_IPREQUESTANS]       = \&unpackAddr;
$packTable[PT_IPREQUESTANS]         = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_IPREQUESTFAIL]    = 'IP request fail';
$unpackTable[PT_IPREQUESTFAIL]      = \&unpackD;
$packTable[PT_IPREQUESTFAIL]        = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERMESSAGE]    = 'Server message';
$unpackTable[PT_SERVERMESSAGE]      = \&unpackS;
$packTable[PT_SERVERMESSAGE]        = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_IDCHANGE]         = 'ID change';
$unpackTable[PT_IDCHANGE]           = \&unpackD;
$packTable[PT_IDCHANGE]             = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERINFO]       = 'Server info';
$unpackTable[PT_SERVERINFO]         = \&unpackInfo;
$packTable[PT_SERVERINFO]           = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_FOUNDSOURCES]     = 'Found sources';
my $unpackFoundSources = sub {
    my ($hash, $addrl);
    defined($hash  = &unpackHash) or return;
    defined($addrl = &unpackAddrList) or return;
#    return {Hash => $hash, Addresses => $addrl};
    return ($hash, $addrl);
};
my $packFoundSources = sub {
#    my ($d) = @_;
#    return packHash($d->{Hash}) . packAddrList($d->{Addresses});
    my ($hash, $addrl) = @_;
    return packHash($hash) . packAddrList($addrl);
};
$unpackTable[PT_FOUNDSOURCES]       = $unpackFoundSources;
$packTable[PT_FOUNDSOURCES]         = $packFoundSources;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHUSERRES]    = 'Search user results';
$unpackTable[PT_SEARCHUSERRES]      = \&unpackInfoList;
$packTable[PT_SEARCHUSERRES]        = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_SENDINGPART]      = 'Sending part';
$unpackTable[PT_SENDINGPART]        = sub {
    my ($hash, $start, $end, $data);
    defined($hash   = &unpackHash) or return;
    defined($start  = &unpackD) or return;
    defined($end    = &unpackD) or return;
    $data = unpack("x$_[1] a*", $_[0]); # copy data for postprocessing
#    return {Hash => $hash, Start => $start, End => $end, Data => \$data};
    return ($hash, $start, $end, \$data);
};
$packTable[PT_SENDINGPART]          = sub {
#    my ($d) = @_;
#    return packHash($d->{Hash}) 
#        . pack('LL a*', $d->{Start}, $d->{End}, $$d->{Data});
    my ($hash, $start, $end, $data) = @_;
    return packHash($hash) . pack('LL a*', $start, $end, $$data)
};
# -------------------------------------------------------------------
$PacketTagName[PT_REQUESTPARTS]     = 'Request parts';
$unpackTable[PT_REQUESTPARTS]       = sub {
    my ($hash, $o, @start, @end);
    defined($hash   = &unpackHash) or return;
    defined($o      = &unpackD) && push(@start, $o) or return;
    defined($o      = &unpackD) && push(@start, $o) or return;
    defined($o      = &unpackD) && push(@start, $o) or return;
    defined($o      = &unpackD) && push(@end, $o) or return;
    defined($o      = &unpackD) && push(@end, $o) or return;
    defined($o      = &unpackD) && push(@end, $o) or return;
#    return {Hash => $hash, Gaps => [sort {$a <=> $b} (@start, @end)]};
    return ($hash, sort {$a <=> $b} (@start, @end));
};
$packTable[PT_REQUESTPARTS]         = sub {
    my $hash = shift;
#    my ($d) = @_;
    my ($gaps, @start, @end);
#    $gaps = $d->{Gaps};
    foreach my $i (0, 2, 4) {
#        push @start, $gaps->[$i];
#        push @end,   $gaps->[$i+1];
        push @start, $_[$i];
        push @end,   $_[$i+1];
    }
    return packHash($hash) . pack('LLLLLL', @start, @end);
#    return packHash($d->{Hash}) . pack('LLLLLL', @start, @end);
};
# -------------------------------------------------------------------
$PacketTagName[PT_NOSUCHFILE]       = 'No such file';
$unpackTable[PT_NOSUCHFILE]         = \&unpackHash;
$packTable[PT_NOSUCHFILE]           = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ENDOFOWNLOAD]     = 'End of download';
$unpackTable[PT_ENDOFOWNLOAD]       = \&unpackHash;
$packTable[PT_ENDOFOWNLOAD]         = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_VIEWFILES]        = 'View files';
$unpackTable[PT_VIEWFILES]          = $unpackEmpty;
$packTable[PT_VIEWFILES]            = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_VIEWFILESANS]     = 'View files answer';
$unpackTable[PT_VIEWFILESANS]       = \&unpackInfoList;
$packTable[PT_VIEWFILESANS]         = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_HELLOANSWER]      = 'Hello answer';
$unpackTable[PT_HELLOANSWER]        = sub {
    my ($uinfo, $sip, $sport);
    defined($uinfo  = &unpackInfo) or return;
    ($uinfo->{ServerIP}, $uinfo->{ServerPort}) = &unpackAddr or return;
    return $uinfo;
};
$packTable[PT_HELLOANSWER]          = sub {
    my ($d) = @_;
    return packInfo($d) . packAddr($d->{ServerIP}, $d->{ServerPort});
};
# -------------------------------------------------------------------
$PacketTagName[PT_NEWCLIENTID]      = 'New client ID';
$unpackTable[PT_NEWCLIENTID]        = sub {
    my ($id, $newid);
    defined($id    = &unpackD) or return;
    defined($newid = &unpackD) or return;
#    return {Users => $users, Files => $files};
    return ($id, $newid);
};
$packTable[PT_NEWCLIENTID]          = sub {
#    my ($d) = @_;
#    return pack('LL', $d->{Users}, $d->{Files});
    return pack('LL', @_);
};
# -------------------------------------------------------------------
$PacketTagName[PT_MESSAGE]          = 'Message';
$unpackTable[PT_MESSAGE]            = \&unpackS;
$packTable[PT_MESSAGE]              = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_FILESTATUSREQ]    = 'File status request';
$unpackTable[PT_FILESTATUSREQ]      = \&unpackHash;
$packTable[PT_FILESTATUSREQ]        = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_FILESTATUS]       = 'File status';
$unpackTable[PT_FILESTATUS]         = sub {
    my ($hash, $nparts, $status);
    defined($hash   = &unpackHash) or return;
    defined($nparts = &unpackW) or return;
    if ($nparts) {
        $status = unpack("x$_[1] b$nparts", $_[0]);
        defined($status) && (length($status) == $nparts) or return;
        $_[1] += ceil $nparts/8;
    }
#    return {Hash => $hash, Status => $status};
    return ($hash, $status);
};
$packTable[PT_FILESTATUS]           = sub {
#   my ($d) = @_;
#   return packHash($d->{Hash}) 
#       . pack('S b*', length $d->{Status}, $d->{Status});
    my ($hash, $status) = @_;
    return packHash($hash) . pack('S b*', length $status, $status);
};
# -------------------------------------------------------------------
$PacketTagName[PT_HASHSETREQUEST]   = 'Hashset request';
$unpackTable[PT_HASHSETREQUEST]     = \&unpackHash;
$packTable[PT_HASHSETREQUEST]       = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_HASHSETANSWER]    = 'Hashset answer';
$unpackTable[PT_HASHSETANSWER]      = sub {
    my ($hash, $nparts, @parthashes, $ph);
    defined($hash   = &unpackHash) or return;
    defined($nparts = &unpackW) or return;
    while ($nparts--) {
        defined($ph = &unpackHash) or return;
        push @parthashes, $ph;
    }
    !$nparts or return;
#    return {Hash => $hash, Parthashes => \@parthashes};
    return ($hash, \@parthashes);
};
$packTable[PT_HASHSETANSWER]        = sub {
    my ($hash, $parthashes) = @_;
#    my ($d) = @_;
#    my $parthashes = $d->{Parthashes};
#    my $res = packHash($d->{Hash}) . packW(@$parthashes+0);
    my $res = packHash($hash) . packW(@$parthashes+0);
    foreach my $ph (@$parthashes) {
        $res .= packHash($ph);
    }
    return $res;
};
# -------------------------------------------------------------------
$PacketTagName[PT_UPLOADREQUEST]    = 'Upload request';
$unpackTable[PT_UPLOADREQUEST]      = $unpackEmpty;
$packTable[PT_UPLOADREQUEST]        = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_UPLOADACCEPT]     = 'Upload accept';
$unpackTable[PT_UPLOADACCEPT]       = $unpackEmpty;
$packTable[PT_UPLOADACCEPT]         = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_CANCELTRANSFER]   = 'Cancel transfer';
$unpackTable[PT_CANCELTRANSFER]     = $unpackEmpty;
$packTable[PT_CANCELTRANSFER]       = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_OUTOFPARTS]       = 'Out of parts';
$unpackTable[PT_OUTOFPARTS]         = $unpackEmpty;
$packTable[PT_OUTOFPARTS]           = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_FILEREQUEST]      = 'File request';
$unpackTable[PT_FILEREQUEST]        = \&unpackHash;
$packTable[PT_FILEREQUEST]          = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_FILEREQANSWER]    = 'File request answer';
$unpackTable[PT_FILEREQANSWER]      = sub {
    my ($hash, $fname);
    defined($hash  = &unpackHash) or return;
    defined($fname = &unpackS) or return;
#    return {Hash => $hash, Name => $fname};
    return ($hash, $fname);
};
$packTable[PT_FILEREQANSWER]        = sub {
    my ($hash, $fname) = @_;
    return packHash($hash) . packS($fname);
#    my ($d) = @_;
#    return packHash($d->{Hash}) . packS($d->{Name});
};
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERSTATUSREQ]  = 'UDP Server status request';
#$unpackTable[PT_UDP_SERVERSTATUSREQ]   = \&;
#$packTable[PT_UDP_SERVERSTATUSREQ]     = \&;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERSTATUS]     = 'UDP Server status';
#$unpackTable[PT_UDP_SERVERSTATUS]      = \&;
#$packTable[PT_UDP_SERVERSTATUS]        = \&;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SEARCHFILE]       = 'UDP Search file';
$unpackTable[PT_UDP_SEARCHFILE]         = \&unpackSearchQuery;
$packTable[PT_UDP_SEARCHFILE]           = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SEARCHFILERES]    = 'UDP Search file result';
$unpackTable[PT_UDP_SEARCHFILERES]      = \&unpackInfo;
$packTable[PT_UDP_SEARCHFILERES]        = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_GETSOURCES]       = 'UDP Get sources';
$unpackTable[PT_UDP_GETSOURCES]         = \&unpackHash;
$packTable[PT_UDP_GETSOURCES]           = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_FOUNDSOURCES]     = 'UDP Found Sources';
$unpackTable[PT_UDP_FOUNDSOURCES]       = $unpackFoundSources;
$packTable[PT_UDP_FOUNDSOURCES]         = $packFoundSources;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_CALLBACKREQUEST]  = 'UDP Callback request';
#$unpackTable[PT_UDP_CALLBACKREQUEST]   = \&;
#$packTable[PT_UDP_CALLBACKREQUEST]     = \&;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_GETSERVERLIST]    = 'UDP Get server list';
$unpackTable[PT_UDP_GETSERVERLIST]      = \&unpackAddr;
$packTable[PT_UDP_GETSERVERLIST]        = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERLIST]       = 'UDP Server list';
$unpackTable[PT_UDP_SERVERLIST]         = sub {
    my ($sip, $sport, $addrl);
    ($sip, $sport) = &unpackAddr or return;
    defined($addrl  = &unpackAddrList) or return;
    return ($sip, $sport, $addrl);
};
$packTable[PT_UDP_SERVERLIST]           = sub {
    my ($sip, $sport, $addrl) = @_;
    return packAddr($sip, $sport) . packAddrList($addrl);
};
# -------------------------------------------------------------------
# -------------------------------------------------------------------

1;
__END__

=head1 NAME

P2P::pDonkey::Packet - Perl extension for handling packets of eDonkey peer2peer protocol. 

=head1 SYNOPSIS

    use Digest::MD4;
    use P2P::pDonkey::Meta qw( makeClientInfo printInfo );
    use P2P::pDonkey::Packet ':all';
    use Data::Hexdumper;

    my $user = makeClientInfo('Muxer', 0, 60, 4662);
    my $raw = packBody(PT_HELLO, $user);
    print hexdump(data => $raw);

    my ($off, $pt) = (0);
    $user = unpackBody(\$pt, $raw, $off);
    print "Packet type: ", PacketTagName($pt), "\n";
    printInfo($user);
  

=head1 DESCRIPTION

The module provides functions and constants for creating, packing and 
unpacking packets of eDonkey peer2peer protocol.

=over

=item PacketTagName(PT_TAG)

    Returns string name of PT_TAG or 'Unknown(PT_TAG)' if name is unknown.
    
=item unpackBody(\$pt, $data, $off)

    Unpacks data and places packet type in $pt. $off is changed to last 
    unpacked byte offset in $data. Packet header is not processed in 
    unpackBody(), so $off should be set on packet type byte offset.
    Returns list of unpacked data in success.
    
=item packBody(PT_TAG, ...) 

    Packs user data in packet with PT_TAG type and returns byte string.
    packet header is not included in result.
    
=back

=head2 eDonkey packet types

    Here listed data, returned by unpackBody() and passed to packBody()
    for each packet type.

=over

=item PT_HELLO

=item PT_HELLOSERVER

=item PT_HELLOCLIENT

=item PT_BADPROTOCOL

=item PT_GETSERVERLIST

=item PT_OFFERFILES

=item PT_SEARCHFILE

=item PT_GETSOURCES

=item PT_SEARCHUSER

=item PT_IPREQUEST

=item PT_MORERESULTS

=item PT_SERVERLIST

=item PT_SEARCHFILERES

=item PT_SERVERSTATUS

=item PT_IPREQUESTANS

=item PT_IPREQUESTFAIL

=item PT_SERVERMESSAGE

=item PT_IDCHANGE

=item PT_SERVERINFO

=item PT_FOUNDSOURCES

=item PT_SEARCHUSERRES

=item PT_SENDINGPART

=item PT_REQUESTPARTS

=item PT_NOSUCHFILE

=item PT_ENDOFOWNLOAD

=item PT_VIEWFILES

=item PT_VIEWFILESANS

=item PT_HELLOANSWER

=item PT_NEWCLIENTID

=item PT_MESSAGE

=item PT_FILESTATUSREQ

=item PT_FILESTATUS

=item PT_HASHSETREQUEST

=item PT_HASHSETANSWER

=item PT_UPLOADREQUEST

=item PT_UPLOADACCEPT

=item PT_CANCELTRANSFER

=item PT_OUTOFPARTS

=item PT_FILEREQUEST

=item PT_FILEREQANSWER

=item PT_UDP_SERVERSTATUSREQ

=item PT_UDP_SERVERSTATUS

=item PT_UDP_SEARCHFILE

=item PT_UDP_SEARCHFILERES

=item PT_UDP_GETSOURCES

=item PT_UDP_FOUNDSOURCES

=item PT_UDP_CALLBACKREQUEST

=item PT_UDP_GETSERVERLIST

=item PT_UDP_SERVERLIST

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Alexey Klimkin, E<lt>klimkin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>, L<P2P::pDonkey::Meta>.

eDonkey home:

=over 4

    <http://www.edonkey2000.com/>

=back

Basic protocol information:

=over 4

    <http://hitech.dk/donkeyprotocol.html>

    <http://www.schrevel.com/edonkey/>

=back

Client stuff:

=over 4

    <http://www.emule-project.net/>

    <http://www.nongnu.org/mldonkey/>

=back

Server stuff:

=over 4

    <http://www.thedonkeynetwork.com/>

=back

=cut
