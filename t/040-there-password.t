#!/usr/bin/perl -Tw

use strict;

use Test::More tests => 13;

use lib "src/perllib";
use_ok("There::Password");

my $pass = There::Password->new();
ok(defined $pass, "new() returned something");
ok($pass->change("tunkki"), "change returned ok");
ok($pass->latest() eq "tunkki", "latest is correct");

my $data = << "EOH";
2009-12-24 joulu
2008-01-22-1 joku muu päivä
2008-01-22-3 joku muu päivä
# kommentti
  # toinen kommentti

# tyhjä rivi oli tos yllä.
2008-01-22-4 ihan sama
2008-01-22 ihan sama
# lopussa on tyhmä rivi

EOH

ok($pass->deserialize("2006-12-01 perseen\n2007-03-04 suti\n", "deserialized"));
ok($pass->latest() eq "suti", "ok");

ok($pass->deserialize($data), "deserialized");
ok($pass->latest() eq "joulu", "ok");
ok($pass->serialize() eq $data, "serialized ok");
ok($pass->history()->[0] =~ m/^2008-01-22 /, "history is fine");
ok($pass->history()->[1] =~ m/^2008-01-22-1 /, "history is fine");
ok($pass->history()->[3] =~ m/^2008-01-22-4 /, "history is fine");

ok(${^TAINT}, "Please make your code -T -compatible.");
