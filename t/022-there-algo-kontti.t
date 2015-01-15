#!/usr/bin/perl -Tw

use Test::More tests => 10;

use lib "src/perllib";
use_ok("There::Algo::Kontti");

my $key = undef;

my $cipher = new There::Algo::Kontti();
ok( defined $cipher, "new() returned something");

is( $cipher->encrypt($key, "Vaan ny jotain"), "Koan vantti ko nyntti kotain jontti", "jotain vaan voi onnistua ryptaan.");

	  
my $frederik = new There::Algo::Kontti;
my $message = "Anna pusu";
my $kysely = $frederik->encrypt($key, $message);
is($kysely, "Konna antti kosu puntti", "konna antti");
local $mother = new There::Algo::Kontti;
ok($mother->decrypt($key, $kysely) eq $message, "definitely not ok.");

foreach my $test ('Kokko, kokoo kokoon koko kokko', 'Haista SINÄ mursu paska',
	'Aina ei voi voittaa, mut KOSKAAN ei o helppoo','')
{
	is($cipher->decrypt($key, $cipher->encrypt($key, $test)), $test,
	$cipher->encrypt($key, $test))
}  


ok(${^TAINT}, "Please make your code -T -compatible.");
