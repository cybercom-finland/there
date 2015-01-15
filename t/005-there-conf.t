#!/usr/bin/perl -Tw

use File::Temp;
use IO::File;
use Test::More tests => 13;

use lib "src/perllib";
use_ok("There::Conf");

local $ENV{'HOME'} = '/doesnotexist';

local $ARGV[0] = "--therepath=/tmp/there";
my $conf = new There::Conf();
ok( defined $conf, "new() returned something");
ok( defined $conf->therepath(), "conf->therepath() returned something");
ok( $conf->therepath() eq "/tmp/there", "which was what we expected");
ok( $conf->therepath("plim"), "which can be changed");
ok( $conf->therepath() eq "plim", "and read again");

ok(There::Conf::clear_cache(), "cleared configuration");
my $tempdir = File::Temp::tempdir("/tmp/thereXXXXX", TEMPDIR => 1, CLEANUP => 1);

if($tempdir =~ m|^(/tmp/there.....)$|)
{
    $tempdir = $1;
}
else
{
    die "tempdir is '$tempdir'";
}

my $rctext = << "EORC";
debug
therepath	$tempdir/there
clearance	tötteröö
EORC
;
local $ENV{PATH} = "";
local $ENV{BASH_ENV} = "";

my $rcfile = new IO::File("$tempdir/.thererc", "w");
ok($rcfile, "created a new rc file");
ok($rcfile->print( $rctext ), "wrote our options into the rc file");
ok($rcfile->close(), "closed the file handle successfully");

local $ENV{HOME} = $tempdir;

$conf = new There::Conf();
ok($conf, "conf was succesfully created w/ rcfile");
is( $conf->therepath(), "$tempdir/there", "therepath was successfully set");
ok( $conf->debug(), "argumentless option was succesfully set");
