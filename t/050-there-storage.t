#!/usr/bin/perl -wT

use strict;

use Test::More tests => 27;

use lib "src/perllib";
use_ok("There::Conf");
use_ok("There::Storage");
use_ok("File::Temp");

my $tempdir = File::Temp::tempdir("thereXXXXX", TEMPDIR => 1, CLEANUP => 1);
#print "tempdir='$tempdir'\n";

local $ARGV[0] = "--therepath=/tmp/there";
my $conf = new There::Conf();
$conf->there($tempdir);

my $clr = "root";

my $s = new There::Storage();
ok(defined($s), "got a new Storage object ok.");
ok($s->create_clearance($clr), "created a clearance");
my @c = $s->list_clearances();
ok($c[0] eq $clr, "and it exists afterwards");

my $key = "key1";
my $data = "tuubaa";


ok($s->store($clr, $key, $data), "stored something");
my @k = $s->list_keys($clr);
ok($k[0] eq $key, "found it again");
ok($s->retrieve($clr, $key) eq $data, "and the contents match!");

#local $ENV{PATH} = "/bin";
#warn `ls -laR $tempdir`;

my $clr2 = "basso";
ok($s->create_clearance($clr2), "created another clearance");
ok($s->replace_clearance($clr, $clr2), "replaced clearance with another");
@k = $s->list_keys($clr);
ok(!@k, "clearance is now empty");
#local $ENV{PATH} = "/bin";
#warn `ls -laR $tempdir`;

ok($s->store($clr, $key, $data), "stored something");
@k = $s->list_keys($clr);
ok($k[0] eq $key, "found the key, so the new clearance works with a different name");

ok(-d "$tempdir/.archive", "an archive has appeared");
local $ENV{PATH} = "/bin";
#warn `ls -lR $tempdir/.archive`;
ok(!system("mv $tempdir/.archive/*/$clr $tempdir/$clr2"), "restored from archive");
@k = $s->list_keys($clr2);
ok($k[0] eq $key, "found $key again");
ok($s->retrieve($clr2, $key) eq $data, "and the contents match!");

ok($s->destroy_clearance($clr), "destroyed a clearance");
my $warning;
local $SIG{'__WARN__'} = sub { $warning = pop };
@k = $s->list_keys($clr);
ok(!@k, "found nothing, as expected");
ok($warning, "and we got a warning");
ok(!defined($s->retrieve($clr, $key)), "nothing must be found anymore");

ok(-d "$tempdir/.archive", "an archive has appeared");
local $ENV{PATH} = "/bin";
ok(!system("mv $tempdir/.archive/*/$clr $tempdir/$clr"), "restored from archive");
@k = $s->list_keys($clr2);
ok($k[0] eq $key, "found $key again");
ok($s->retrieve($clr2, $key) eq $data, "and the contents match!");


ok(${^TAINT}, "Please make your code -T -compatible.");
