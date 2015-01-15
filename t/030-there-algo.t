#!/usr/bin/perl -Tw

use strict;

use Test::More;

use lib "src/perllib";
use_ok("There::Algo");

my $tests = 1;

my $key = "porkkane";
my @algonames = There::Algo::get_algorithms();

foreach my $algoname (@algonames)
{
  my $algo = There::Algo->new($algoname);
  ok(defined $algo, "new($algoname) returned something");
  is($algo->decrypt($key, $algo->encrypt($key, 'up/dn')), 'up/dn', "$algoname works as expected");
  is($algo->algoname(), $algoname, "algo $algoname correctly returns algoname");
  $tests+=3;
}

done_testing( $tests );
