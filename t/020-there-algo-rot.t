#!/usr/bin/perl -Tw

use Test::More tests => 41;

use lib "src/perllib";
use_ok("There::Algo::Rot");

my $key = undef;

my $cipher = new There::Algo::Rot("up/dn");
ok( defined $cipher, "new() returned something");
ok( defined $cipher->mode(), "cipher->mode() returned something");
ok( $cipher->encrypt($key, "dndod") eq "popup", "dndod encrypts to popup");
ok( $cipher->decrypt($key, "dndod") eq "popup", "dndod decrypts to popup");
ok( $cipher->encrypt($key, "poliisiauto, musta (vm -69)") eq 
    "(69- w^) etsnw 'otneisiilod", "poliisiauto encrypts correctly");

my $caesar = new There::Algo::Rot("13");
ok( $caesar->decrypt($key, "Prgrehz prafrb, Pneguntvarz rffr qryraqnz") eq
    "Ceterum censeo, Carthaginem esse delendam", "rot13 works");

my $dada = join "", map {(chr(), chr())} (0..255);
ok( length($dada)>200, "test case initialized more or less correctly");

foreach $mode (0..30,"up/dn")
{    
    $cipher->mode($mode);
    ok($dada eq $cipher->decrypt($key, $cipher->encrypt($key, $dada)), 
	"rot$mode works.");
}

ok(${^TAINT}, "Please make your code -T -compatible.");
