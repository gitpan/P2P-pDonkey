# P2P::pDonkey::Meta.pm
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Meta;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = 
( 'all' => [ qw(
                MetaTagName

                SZ_FILEPART

                VT_STRING VT_INTEGER 
                ST_COMBINE ST_AND ST_OR ST_ANDNOT 
                ST_NAME 
                ST_META 
                ST_MINMAX ST_MIN ST_MAX

                TT_UNDEFINED
                TT_NAME TT_SIZE TT_TYPE TT_FORMAT TT_COPIED TT_GAPSTART TT_GAPEND
                TT_DESCRIPTION TT_PING TT_FAIL TT_PREFERENCE TT_PORT TT_IP TT_VERSION
                TT_TEMPFILE TT_PRIORITY TT_STATUS TT_AVAILABILITY

                packB unpackB 
                packW unpackW
                packD unpackD
                packF unpackF
                packS unpackS
                packHash unpackHash
                packHashList unpackHashList

                packMetaTagName unpackMetaTagName
                packMeta unpackMeta makeMeta sameMetaType
                packMetaList unpackMetaList
                packMetaListU unpackMetaListU

                packInfo unpackInfo makeClientInfo makeServerInfo printInfo
                packInfoList unpackInfoList
                
                packFileInfo unpackFileInfo makeFileInfo 
                packFileInfoList unpackFileInfoList
                makeFileInfoList 

                packSearchQuery unpackSearchQuery matchSearchQuery

                packAddr unpackAddr
                packAddrList unpackAddrList 

               ) ],
  'tags' => [ qw(
                SZ_FILEPART

                VT_STRING VT_INTEGER 
                ST_COMBINE ST_AND ST_OR ST_ANDNOT 
                ST_NAME 
                ST_META 
                ST_MINMAX ST_MIN ST_MAX

                TT_UNDEFINED
                TT_NAME TT_SIZE TT_TYPE TT_FORMAT TT_COPIED TT_GAPSTART TT_GAPEND
                TT_DESCRIPTION TT_PING TT_FAIL TT_PREFERENCE TT_PORT TT_IP TT_VERSION
                TT_TEMPFILE TT_PRIORITY TT_STATUS TT_AVAILABILITY
                ) ] 
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

use Carp;
use File::Glob ':glob';
use Tie::IxHash;
use Digest::MD4;
use File::Basename;
use File::Find;
use POSIX qw( ceil );
use P2P::pDonkey::Util qw( ip2addr );

use Video::Info;

my $debug = 0;

my @MetaTagName;
sub MetaTagName {
    return $MetaTagName[$_[0]];
}

use constant SZ_FILEPART        => 9500*1024;

# --- value types
use constant VT_STRING          => 0x02;
use constant VT_INTEGER         => 0x03;
use constant VT_FLOAT           => 0x04;
# --- search query constants
# - search type
use constant ST_COMBINE         => 0x0;
use constant ST_NAME            => 0x1;
use constant ST_META            => 0x2;
use constant ST_MINMAX          => 0x3;
# - search logic op for combined
use constant ST_AND             => 0x0;
use constant ST_OR              => 0x1;
use constant ST_ANDNOT          => 0x2;
# - constants for ST_MINMAX
use constant ST_MIN             => 0x1;
use constant ST_MAX             => 0x2;
# --- tag types
use constant TT_UNDEFINED       => 0x00;
use constant TT_NAME            => 0x01;
use constant TT_SIZE            => 0x02;
use constant TT_TYPE            => 0x03;    # Audio, Video, Image, Pro, Doc, Col
use constant TT_FORMAT          => 0x04;    # file extension
use constant TT_COPIED          => 0x08;
use constant TT_GAPSTART        => 0x09;
use constant TT_GAPEND          => 0x0a;
use constant TT_DESCRIPTION     => 0x0b;
use constant TT_PING            => 0x0c;
use constant TT_FAIL            => 0x0d;
use constant TT_PREFERENCE      => 0x0e;
use constant TT_PORT            => 0x0f;
use constant TT_IP              => 0x10;
use constant TT_VERSION         => 0x11;
use constant TT_TEMPFILE        => 0x12;
use constant TT_PRIORITY        => 0x13;
use constant TT_STATUS          => 0x14;
use constant TT_AVAILABILITY    => 0x15;
use constant _TT_LAST           => 0x16;
$MetaTagName[TT_NAME]           = 'Name';
$MetaTagName[TT_SIZE]           = 'Size';
$MetaTagName[TT_TYPE]           = 'Type';
$MetaTagName[TT_FORMAT]         = 'Format';
$MetaTagName[TT_COPIED]         = 'Copied';
$MetaTagName[TT_GAPSTART]       = 'Gap start';
$MetaTagName[TT_GAPEND]         = 'Gap end';
$MetaTagName[TT_DESCRIPTION]    = 'Description';
$MetaTagName[TT_PING]           = 'Ping';
$MetaTagName[TT_FAIL]           = 'Fail';
$MetaTagName[TT_PREFERENCE]     = 'Preference';
$MetaTagName[TT_PORT]           = 'Port';
$MetaTagName[TT_IP]             = 'IP';
$MetaTagName[TT_VERSION]        = 'Version';
$MetaTagName[TT_TEMPFILE]       = 'Temp file';
$MetaTagName[TT_PRIORITY]       = 'Priority';
$MetaTagName[TT_STATUS]         = 'Status';
$MetaTagName[TT_AVAILABILITY]   = 'Availability';

# basic pack/unpack functions
sub unpackB {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] C", $_[0]);
        $_[1] += 1 if defined $res;
    } else {
        $res = unpack('C', $_[0]);
    }
    return $res;
}

sub unpackW {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] S", $_[0]);
        $_[1] += 2 if defined $res;
    } else {
        $res = unpack('S', $_[0]);
    }
    return $res;
}

sub unpackD {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] L", $_[0]);
        $_[1] += 4 if defined $res;
    } else {
        $res = unpack('L', $_[0]);
    }
    return $res;
}

sub unpackF {
    my $res;
    if (defined $_[1]) {
        $res = unpack("x$_[1] f", $_[0]);
        $_[1] += 4 if defined $res;
    } else {
        $res = unpack('f', $_[0]);
    }
    return $res;
}

sub unpackS {
    my ($res, $len);
    if (defined $_[1]) {
        defined($len = unpack("x$_[1] S", $_[0])) or return;
        defined($res = unpack("x$_[1] x2 a$len", $_[0])) or return;
        length($res) == $len or return;
        $_[1] += 2; 
        $_[1] += $len;
    } else {
        defined($len = unpack('S', $_[0])) or return;
        $res = unpack("x2 a$len", $_[0]);
    }
    return $res;
}

sub unpackHash {
    my $res = unpack("x$_[1] H32", $_[0]);
    length($res) == 32 or return;
    $_[1] += 16;
    return $res;
}

sub unpackHashList {
    my ($n, @res, $hash);
    defined($n = &unpackW) or return;
    while ($n--) {
        defined($hash = &unpackHash) or return;
        push @res, $hash;
    }
    return \@res;
}

#
sub packB {
    return pack('C', shift);
}
sub packW {
    return pack('S', shift);
}
sub packD {
    return pack('L', shift);
}
sub packF {
    return pack('f', shift);
}
sub packS {
    return pack('Sa*', length $_[0], $_[0]);
}
sub packHash {
    return pack('H32', $_[0]);
}
sub packHashList {
    my ($l) = @_;
    my ($res, $hash);
    $res = packW(@$l+0);
    foreach $hash (@$l) {
        $res .= packHash($hash);
    }
    return $res;
}

# Meta Tag
sub makeMeta {
    my ($st, $value, $name) = @_;
    my $vt;
    if ($st == TT_NAME || $st == TT_DESCRIPTION 
            || $st == TT_TYPE || $st == TT_FORMAT
            || $st == TT_TEMPFILE) {
        $vt = VT_STRING;
    } else {
        $vt = VT_INTEGER;
    }
    return {Type => $st, ValType => $vt, Value => $value, 
            Name => $st ? MetaTagName($st) : $name};
}

sub sameMetaType {
    my ($m1, $m2) = @_;
    return $m1 && $m2 && $m1->{ValType} == $m2->{ValType} 
        && ($m1->{Type} 
            ? $m1->{Type} == $m2->{Type}
            : $m1->{Name} eq $m2->{Name});
}

sub unpackMetaTagName {
    my ($name, $st, $len);

    defined($name = &unpackS) or return;
    ($len = length $name) or return;   # length is not 0
    $st = ord $name;

    if ($st < _TT_LAST) {   # special tag
        if ($st == TT_GAPEND || $st == TT_GAPSTART) {
            $name = unpack('xa*', $name);
        } elsif ($len == 1) {
            $name = MetaTagName($st);
            $name = sprintf("Unknown(0x%x)", $st) if !$name;
        } else {
            $st = TT_UNDEFINED;
        }
    }
    return {Type => $st, Name => $name};
}
sub packMetaTagName {
    my ($meta) = @_;
    my ($st, $name) = ($meta->{Type}, $meta->{Name});

    if ($st == TT_GAPSTART || $st == TT_GAPEND) {
        $name = packB($st) . $name;
    } elsif ($st) {
        $name = packB($st);
    }
    return packS($name);
}

sub unpackMeta {
    my ($vt, $val, $meta);

    defined($vt     = &unpackB) or return;
    defined($meta   = &unpackMetaTagName) or return;

    if ($vt == VT_STRING) {
        $val = &unpackS;
    } elsif ($vt == VT_INTEGER) {
        $val = &unpackD;
    } elsif ($vt == VT_FLOAT) {
        $val = &unpackF;
    } else {
        return;
    }
    defined($val) or return;

    $meta->{ValType} = $vt;
    $meta->{Value}   = $val;
    return $meta;
}
sub packMeta {
    my ($meta) = @_;
    my ($vt, $val) = ($meta->{ValType}, $meta->{Value});
    my $res = packB($vt) . packMetaTagName($meta);
    if ($vt == VT_STRING) {
        $res .=  packS($val);
    } elsif ($vt == VT_INTEGER) {
        $res .=  packD($val);
    } elsif ($vt == VT_FLOAT) {
        $res .=  packF($val);
    } else {
        confess "Incorrect meta tag value type!\n";
    }
    return $res;
}

# list of references to meta tags
sub unpackMetaList {
    my ($ntags, @res, $meta);

    defined($ntags = &unpackD) or return;
    while ($ntags--) {
        defined($meta = &unpackMeta) or return;
        push @res, $meta;
    }
    return \@res;
}
sub packMetaList {
    my ($l) = @_;
    my ($res, $meta);
    $res = packD(@$l+0);
    foreach $meta (@$l) {
        $res .= packMeta($meta);
    }
    return $res;
}

# hash of references to meta
sub unpackMetaListU {
    my ($ntags, %res, $meta);

    tie %res, "Tie::IxHash";
    defined($ntags = &unpackD) or return;
    while ($ntags--) {
        defined($meta = &unpackMeta) or return;
        $res{$meta->{Name}} = $meta;
    }
    return \%res;
}
sub packMetaListU {
    my ($res, $meta);
    my $ntags = 0;
    $res = '';
    while ((undef, $meta) = each %{$_[0]}) {
        $res .= packMeta($meta);
        $ntags++;
    }
    return packD($ntags) . $res;
}

sub MetaList2MetaListU {
    my ($l) = @_;
    my %res;
    tie %res, "Tie::IxHash";
    foreach my $meta (@$l) {
        $res{$meta->{Name}} = $meta;
    }
    return \%res;
}

sub MetaListU2MetaList {
    return [values %{$_[0]}];
}

# client or server info
sub unpackInfo {
    my ($hash, $ip, $port, $meta);
    defined($hash = &unpackHash) or return;
    (($ip, $port) = &unpackAddr) or return;
    defined($meta = &unpackMetaListU) or return;
    return {Hash => $hash, IP => $ip, Port => $port, Meta => $meta};
}

sub packInfo {
    my ($d) = @_;
    return packHash($d->{Hash}) . packAddr($d->{IP}, $d->{Port}) 
        . packMetaListU($d->{Meta});
}

sub unpackInfoList {
    my ($nres, @res, $info);
    defined($nres   = &unpackD) or return;
    while ($nres--) {
        defined($info = &unpackInfo) or return;
        push @res, $info;
    }
    return \@res;
}

sub packInfoList {
    my ($l) = @_;
    my ($res, $info);
    $res = packD(@$l+0);
    foreach $info (@$l) {
        $res .= packInfo($info);
    }
    return $res;
}

sub makeClientInfo {
    my ($ip, $port, $nick, $version) = @_;
    my (%meta, $hash);;
    $hash = Digest::MD4->hexhash($nick);
    tie %meta, "Tie::IxHash";
    $meta{Name}     = makeMeta(TT_NAME, $nick);
    $meta{Version}  = makeMeta(TT_VERSION, $version);
    $meta{Port}     = makeMeta(TT_PORT, $port);
    return {Hash => $hash, IP => $ip, Port => $port, Meta => \%meta};
}

sub makeServerInfo {
    my ($ip, $port, $name, $description) = @_;
    my (%meta, $hash);;
    $hash = Digest::MD4->hexhash($name);
    tie %meta, "Tie::IxHash";
    $meta{Name}         = makeMeta(TT_NAME, $name);
    $meta{Description}  = makeMeta(TT_DESCRIPTION, $description);
    return {Hash => $hash, IP => $ip, Port => $port, Meta => \%meta};
}

# file info
sub unpackFileInfo {
    my (%res, $metas, %tags, @gaps);
    defined($res{Date}  = &unpackD) || return;
    defined($res{Hash}  = &unpackHash) || return;
    defined($res{Parts} = &unpackHashList) || return;
    defined($metas  = &unpackMetaList) || return;

    tie %tags, "Tie::IxHash";
    foreach my $meta (@$metas) {
        if ($meta->{Type} == TT_GAPSTART || $meta->{Type} == TT_GAPEND) {
            push @gaps, $meta->{Value};
        } else {
            $tags{$meta->{Name}} = $meta;
        }
    }
    $res{Gaps} = [sort {$a <=> $b} @gaps];
    $res{Meta} = \%tags;
    return \%res;
}

sub packFileInfo {
    my ($d) = @_;
    my ($res, $metas, $gaps, $ngaps);
    $res = packD($d->{Date}) . packHash($d->{Hash}) . packHashList($d->{Parts});
    $metas = MetaListU2MetaList($d->{Meta});
    $gaps = $d->{Gaps};
    $ngaps = @$gaps / 2;
    for (my ($i, $n) = (0, 0); $i < $ngaps; $i += 2, $n++) {
        push @$metas, makeMeta(TT_GAPSTART, $gaps->[$i], $n);
    }
    for (my ($i, $n) = (0, 0); $i < $ngaps; $i += 2, $n++) {
        push @$metas, makeMeta(TT_GAPEND, $gaps->[$i+1], $i);
    }
}

sub unpackFileInfoList {
    my ($nres, @res, $info);
    defined($nres   = &unpackD) or return;
    while ($nres--) {
        defined($info = &unpackFileInfo) or return;
        push @res, $info;
    }
    return \@res;
}

sub packFileInfoList {
    my ($l) = @_;
    my ($res, $info);
    $res = packD(@$l+0);;
    foreach $info (@$l) {
        $res .= packFileInfo($info);
    }
    return $res;
}

sub makeFileInfo {
    my ($path) = @_;
    my ($base, $ext);
    my ($context, %meta, $hash, $type);

    $path = bsd_glob($path, GLOB_TILDE);

    (-e $path && -r _) or return;

    print "Making info for $path\n" if $debug;

#    my $vinfo = Video::Info->new(-file => $path);
#    if ($vinfo->type()) {
#    print $vinfo->filename, "\n";
#    print $vinfo->filesize(), "\n";
#    print $vinfo->type(), "\n";
#    print $vinfo->duration(), "\n";
#    print $vinfo->minutes(), "\n";
#    print $vinfo->MMSS(), "\n";
#    print $vinfo->geometry(), "\n";
#    print $vinfo->title(), "\n";
#    print $vinfo->author(), "\n";
#    print $vinfo->copyright(), "\n";
#    print $vinfo->description(), "\n";
#    print $vinfo->rating(), "\n";
#    print $vinfo->packets(), "\n";
#    }

    ($base, undef, $ext) = fileparse($path, '\..*');
    $ext = unpack('xa*', $ext) if $ext; # skip first '.'
    if ($ext) {
        my %ft = qw(mp3 Audio avi Video gif Image iso Pro doc Doc);
        $type = $ft{lc $ext};
    }

    my ($size, $date);
    $size = (stat _)[7];
    $date = (stat _)[9];

    tie %meta, "Tie::IxHash";
    $meta{Name}   = makeMeta(TT_NAME, "$base.$ext");
    $meta{Size}   = makeMeta(TT_SIZE, $size);
    $meta{Type}   = makeMeta(TT_TYPE, $type) if $type;
    $meta{Format} = makeMeta(TT_FORMAT, $ext) if $ext;

    open(HANDLE, $path) or return;
    binmode(HANDLE);

    $context = new Digest::MD4;
    $context->addfile(\*HANDLE);
    $hash = $context->hexdigest();

    my @parts = ();
    if ($size > SZ_FILEPART) {
        seek(HANDLE, 0, 0);
        my ($nparts, $part);
        $nparts = ceil($size / SZ_FILEPART);
        for (my $i = 0; $i < $nparts; $i++) {
            read(HANDLE, $part, SZ_FILEPART);
            push @parts, Digest::MD4->hexhash($part);
        }
    }
    
    close HANDLE;

    return {Date => $date, Hash => $hash, Parts => \@parts, Meta => \%meta, Path => $path};
}

sub makeFileInfoList {
    my (@res, $info);
    @res = ();
    foreach my $pattern (@_) {
        find { wanted => sub { push(@res, makeFileInfo($File::Find::name)) if -f $File::Find::name}, no_chdir => 1 }, 
            bsd_glob($pattern, GLOB_TILDE);
    }
    return \@res;
}

sub printInfo {
    my ($info) = @_;
    $info or return;

    if (defined $info->{Date}) {
        print "Date: ", scalar(localtime($info->{Date})), "\n";
    }

    if (defined $info->{IP}) {
        print "IP: ", ip2addr($info->{IP}), "\n";
    }

    if (defined $info->{Port}) {
        print "Port: $info->{Port}\n";
    }

    if (defined $info->{Hash}) {
        print "Hash: $info->{Hash}\n";
    }

    if ($info->{Parts}) {
        print "Parts:\n";
        my $i = 0;
        foreach my $parthash (@{$info->{Parts}}) {
            print "\t$i: $parthash\n";
            $i++;
        }
    }

    if ($info->{Gaps}) {
        print "Gaps:\n";
        my $gaps = $info->{Gaps};
        for (my $i = 0; $i < @$gaps/2; $i += 2) {
            print "\t$gaps->[$i] - $gaps->[$i+1]\n";
        }
    }

    if ($info->{Meta}) {
        my ($name, $meta);
        print "Meta:\n";
        while (($name, $meta) = each %{$info->{Meta}}) {
            print "\t$name: $meta->{Value}\n";
        }
    }
}

# search query
sub unpackSearchQuery {
    my ($t);
    defined($t = &unpackB) or return;

    if ($t == ST_COMBINE) {
        my ($op, $exp1, $exp2);
        defined($op     = &unpackB) or return;
        defined($exp1   = &unpackSearchQuery) or return;
        defined($exp2   = &unpackSearchQuery) or return;
        return {Type => $t, Op => $op, Q1 => $exp1, Q2 => $exp2};

    } elsif ($t == ST_NAME) {
        my $str;
        defined($str = &unpackS) or return;
        return {Type => $t, Value => $str};

    } elsif ($t == ST_META) {
        my ($val, $metaname);
        defined($val      = &unpackS) or return;
        defined($metaname = &unpackMetaTagName) or return;
        return {Type => $t, Value => $val, MetaName => $metaname};

    } elsif ($t == ST_MINMAX) {
        my ($val, $metaname, $comp);
        defined($val      = &unpackD) or return;
        defined($comp     = &unpackB) or return;
        ($comp == ST_MIN || $comp == ST_MAX) or return;
        defined($metaname = &unpackMetaTagName) or return; 
        return {Type => $t, Value => $val, Compare => $comp, MetaName => $metaname};

    } else {
        return;
    }
}
sub packSearchQuery {
    my ($d) = @_;
    my ($res, $t);
    $res = packB($t = $d->{Type});

    if ($t == ST_COMBINE) {
        return $res . packB($d->{Op}) 
            . packSearchQuery($d->{Q1})
            . packSearchQuery($d->{Q2});

    } elsif ($t == ST_NAME) {
        return $res . packS($d->{Value});

    } elsif ($t == ST_META) {
        return $res . packS($d->{Value}) . packMetaTagName($d->{MetaName});

    } elsif ($t == ST_MINMAX) {
        return $res . packD($d->{Value}) . packB($d->{Compare})
            . packMetaTagName($d->{MetaName});

    } else {
        confess "Incorrect search query type!\n";
    }
}

sub matchSearchQuery {
    my ($q, $i) = @_;
    my $t = $q->{Type};

    if ($t == ST_COMBINE) {
        my $op = $q->{Op};

        if ($op == ST_AND) {
            return matchSearchQuery($q->{Q1}, $i) && matchSearchQuery($q->{Q2}, $i);
        } elsif ($op == ST_OR) {
            return matchSearchQuery($q->{Q1}, $i) || matchSearchQuery($q->{Q2}, $i);
        } elsif ($op == ST_ANDNOT) {
            return matchSearchQuery($q->{Q1}, $i) && !matchSearchQuery($q->{Q2}, $i);
        } else {
            return;
        }

    } elsif ($t == ST_NAME) {
        my ($mm, $qval);
        $qval = $q->{Value};
        $mm = $i->{Meta}->{Name};

        return ($mm && $mm->{Value} =~ /$qval/);

    } elsif ($t == ST_META) {
        my $mm = $i->{Meta}->{$q->{MetaName}->{Name}};

        return unless $mm && $mm->{ValType} == VT_STRING;

        return $mm->{Value} eq $q->{Value};

    } elsif ($t == ST_MINMAX) {
        my $mm = $i->{Meta}->{$q->{MetaName}->{Name}};

        return unless $mm && $mm->{ValType} == VT_INTEGER;

        if ($q->{Compare} == ST_MIN) {
            return $mm->{Value} >= $q->{Value};
        } elsif ($q->{Compare} == ST_MAX) {
            return $mm->{Value} <= $q->{Value};
        } else {
            return;
        }

    } else {
        return;
    }
}

# list (ip1 port1 ip2 port2 ..)
sub unpackAddrList {
    my ($snum, $ip, $port, @res);

    defined($snum = &unpackB) or return;

    while ($snum--) {
        defined($ip   = &unpackD) or return;
        defined($port = &unpackW) or return;
        push @res, $ip, $port;
    }
    return \@res;
}
sub packAddrList {
    my ($l) = @_;
    my $n = @$l / 2;
    return pack('C', $n) . pack('LS' x $n, @$l);
}

sub unpackAddr {
    my ($ip, $port);
    defined($ip   = &unpackD) or return;
    defined($port = &unpackW) or return;
    return ($ip, $port);
}

sub packAddr {
    return pack('LS', @_);
}

1;
__END__

=head1 NAME

P2P::pDonkey::Meta - Perl extension for handling meta data of eDonkey
peer2peer protocol. 

=head1 SYNOPSIS

  use P2P::pDonkey::Meta ':all';
  my $d = makeFileInfo('baby.avi');
  printInfo($d);

=head1 DESCRIPTION

The module provides functions and constants for creating, packing and 
unpacking meta data from packets of eDonkey peer2peer protocol.

=head2 EXPORT

None by default.

=head1 AUTHOR

Alexey Klimkin, E<lt>klimkin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>.

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
