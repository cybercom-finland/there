#!/usr/bin/perl -wT

use strict;

use Test::More tests => 16;

use lib "src/perllib";
use_ok("There::Directory");
use_ok("There::Conf");
use_ok("File::Temp");

my $tempdir = File::Temp::tempdir("thereXXXXX", TEMPDIR => 1, CLEANUP => 1);

local $ARGV[0] = "--therepath=/tmp/there";
my $conf = new There::Conf();
$conf->there($tempdir);

my $clr = "root";

my $dir = new There::Directory;

ok(defined $dir, "got a new directory object");
ok($dir->update("aroot", "root", 'root password for "a" network machines'), "did an update");
ok($dir->update("proot",   "root", 'a different root password'), "did another update");
ok($dir->update("proot",   "spy", 'a different clearance'), "did yet another update");
ok($dir->update("proot", "spy", 'changed it!'), "did yet another update");
ok($dir->update("aroot",   "aroot", 'another root password'), "did another update");
my @found = ();
ok(@{$dir->search('etwo')} == 1, 
   "search('etwo') found something");
ok(@{$dir->clearance_search('spy', 'proot')} == 1, 
   "clearance_search('spy', 'proot') found something");
ok(@found = @{$dir->search('')},
   "search('') found something (hopefully everything)");
ok(@found = @{$dir->search()},
   "search() found something (hopefully everything)");
ok($found[0]->match("another"), "sorting works");
ok(@found == 4, "4 inserts and 1 update add up to 4 entries"); 

#print for @found;

ok(${^TAINT}, "Please make your code -T -compatible.");
