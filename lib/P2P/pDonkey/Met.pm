# P2P::pDonkey::Met.pm
#
# Copyright (c) 2002 Alexey Klimkin <klimkin@mail.ru>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Met;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use P2P::pDonkey ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    ReadServerMet WriteServerMet PrintServerMet	
	ReadPartMet
) ],
                  'server' => [ qw(
    ReadServerMet WriteServerMet PrintServerMet	
) ],
                  'part'   => [ qw(
	ReadPartMet
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

use Carp;
use Data::Hexdumper;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Util qw( ip2addr );

my $debug = 0;

# Preloaded methods go here.

use constant MT_SERVERMET   => 0x0e;
use constant MT_PARTMET     => 0xe0;


# ---------- server.met handling ---------------------------------------------
# parse server.met file && create hash
sub ReadServerMet {
    my ($fname, $servers) = @_;

    $fname && $servers || croak "ReadServerMet(<filename>, <reference to hash>)\n";
    
    my ($nserv, $IP, $Port, $val, $metas);
    my $buf;
    my $off = 0;

    my $handle;
    my $rs = $/;
    undef $/;
    open($handle, "<$fname") || (carp "Can't open `$fname': $!\n" && return 0);
    binmode($handle);
    if (read($handle, $val, 1) != 1 || unpack('C',$val) != MT_SERVERMET) {
        carp "File '$fname' is not in \"met\" format\n";
        close($handle);
        return 0;
    }
    $buf = <$handle>;
    close $handle;
    $/ = $rs;

    defined($nserv  = unpackD($buf, $off)) or return 0;

    print "servers: $nserv\n" if $debug;
    for my $i (0 .. $nserv-1) {
        ($IP, $Port)    = unpackAddr($buf, $off) or return $i;
        print "$i: " . ip2addr($IP) .":$Port\n" if $debug;

        defined($metas  = unpackMetaListU($buf, $off)) or return $i;
        if ($debug) {
            my ($name, $meta);
            while (($name, $meta) = each %$metas) {
                print "\t$name: $meta->{Value}\n";
            }
        }
#delete $servers->{$IP}{$Port};

        $servers->{ip2addr($IP).":$Port"} = $metas;
    }

    my $tail = length($buf) - $off;
    print "$tail unhandled bytes at the end:\n", hexdump(data=>$buf, start_position=>$off) if $tail;

    return $nserv;
}

sub WriteServerMet {
    my ($fname, $servers) = @_;
    my $nserv = 0;
    my ($IP, $Port, $ports, $tags);

#    while (($IP, $ports) = each(%$servers)) {
#        while (($Port, $tags) = each(%$ports)) {
#            $buffer .= packD($IP) . packW($Port) . packMetaListU($tags);
    my $addr;
    my $buffer = '';
    while (($addr, $tags) = each %$servers) {
        $buffer .= packAddr($tags->{IP}, $tags->{Port}) . packMetaListU($tags);
            $nserv++;
#        }
    }

    my $handle;
    open($handle, ">$fname") || (carp "Can't open `$fname': $!\n" && return 0);
    binmode($handle);
    print $handle packB(MT_SERVERMET) . packD($nserv) . $buffer;
    close $handle;
    return $nserv;
}

# print hash of servers in text format
sub PrintServerMet {
    my ($servers) = @_;
    my ($IP, $Port, $ports, $tags);

#    while (($IP, $ports) = each(%$servers)) {
#        while (($Port, $tags) = each(%$ports)) {
#            print ip2addr($IP), ":$Port\n";
    my $addr;
    while (($addr, $tags) = each %$servers)
    {
        print "$addr\n";
            my ($name, $meta);
            while (($name, $meta) = each %$tags) {
                print "\t$name: ",
                    $meta->{Type} == TT_IP
                        ? ip2addr($meta->{Value})
                        : $meta->{Value},
                        "\n";
            }
#        }
    }
}

sub ReadPartMet {
    my ($fname) = @_;
    $fname || return;

    my $buf;
    my $off = 0;
    my ($handle, $val, %res, $metas);

    my $rs = $/;
    undef $/;
    open($handle, "<$fname") || (carp "Can't open `$fname': $!\n" && return);
    binmode($handle);
    if (read($handle, $val, 1) != 1 || unpack('C',$val) != MT_PARTMET) {
#        warn "File '$fname' is not in \"met\" format";
        close($handle);
        return;
    }
    $buf = <$handle>;
    close $handle;
    $/ = $rs;

    return unpackFileInfo($buf, $off);
}

1;
__END__

=head1 NAME

P2P::pDonkey::Met - Perl extension for handling *.met files of
eDonkey peer2peer protocol.

=head1 SYNOPSIS

    use Tie::IxHash;
    use P2P::pDonkey::Met ':all';

    ...

    my (%servers, $nserv);
    tie %servers, "Tie::IxHash";
    $nserv = ReadServerMet($ARGV[0] || 'server.met', \%servers);
    PrintServerMet(\%servers);
    print "Servers: $nserv\n";

    ...

    foreach my $f (@ARGV) {
        my $p = ReadPartMet($f);
        if ($p) {
            printInfo($p);
        } else {
            print "$f is not in part.met format\n";
        }
    }

=head1 DESCRIPTION

The module provides functions for reading, printing and writing *.met
files of eDonkey peer2peer protocol.

C<P2P::pDonkey::Met> provides the following subroutines:

=over 4

=item ReadServerMet

=item WriteServerMet

=item PrintServerMet

=item ReadPartMet

=item WritePartMet - not yet

=back

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
