#!/usr/bin/perl -Tw

use strict;

use Test::More tests => 17;

use lib "src/perllib";
use_ok("There::PasswordGenerator");

foreach my $round (1..2)
{
  # this may hang if /dev/random runs out of entropy
  my $pass = There::PasswordGenerator::gimme8();
  ok(defined $pass, "round $round, gimme8() returned something");
  is(length($pass), length("my pen's"), "generated password was of perfect length");
  is(($pass =~ y/a-zA-Z0-9//), 8, "all alphanumeric");
  is(($pass =~ y/1Il5S0O//), 0, "no hard-to-read letters");

  my $betterpass = There::PasswordGenerator::gimme16();
  ok(defined $betterpass, "round $round, gimme16() returned something");
  is(length($betterpass), length("twice that pen's"), "generated password was of perfect length");
  is(($betterpass =~ y/a-zA-Z0-9//), 16, "all alphanumeric");
  is(($betterpass =~ y/1Il5S0O//), 0, "no hard-to-read letters");
}
