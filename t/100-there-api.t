#!perl -wT

use strict;

use Test::More tests => 25;

use lib "src/perllib";
use_ok("There::API");
use_ok("There::Conf");
use_ok("File::Temp");

my $tempdir = File::Temp::tempdir("thereXXXXX", TEMPDIR => 1, CLEANUP => 1);

my $warning;
local $SIG{'__WARN__'} = sub {$warning = pop};

local $ARGV[0] = "--therepath=/tmp/there";
my $conf = new There::Conf();
$conf->there($tempdir);

my $clr = "klearanssi";
my $algoname = "AES";
my $pass = "plöps ööks";
my $pass_nok = "ihan väärä kala";

my $api = new There::API;

ok($api->create_clearance($clr, $algoname, $pass), "create clearance");

ok(!$api->check_passphrase($clr, $pass_nok), "check clearance, wrong passphrase");
ok($warning, "got a warning about wrong passphrase");
$warning = undef;

ok($api->check_passphrase($clr, $pass), "check clearance, right passphrase");

my $passid = "voi.aly";
my $newpass = "piste fi";

ok(!$api->change_password( $clr, $passid, $newpass, $pass ), 
   "change should fail before create");
ok($api->create_password( $clr, $passid, $newpass, $pass ), 
   "stored a password");
ok(! $api->create_password( $clr, $passid, $newpass, $pass ), 
   "recreation must fail");
ok($api->store_password( $clr, $passid, $newpass, $pass ), 
   "re-stored a password");
ok($api->change_password( $clr, $passid, $newpass, $pass ), 
   "change should work after create");

ok($api->get_password( $clr, $passid, $pass_nok ) == 0, "and did not get it back with a wrong phrase");
ok($warning, "got a warning about wrong passphrase");
$warning = undef;
ok($api->get_password( $clr, $passid, "" ) == 0, "empty phrase is also considered wrong");
ok($warning, "got a warning about wrong (empty) passphrase");
$warning = undef;
ok(! defined $api->get_password( $clr, $passid, undef ), "got undef with undefined phrase");
ok($warning, "got a warning about wrong (empty) passphrase");
$warning = undef;
is($api->get_password( $clr, $passid, $pass )->latest(), $newpass, "and got it back!");
ok(!$warning, "no warning from good passphrase");

# passphrase change only copies known passwords
my $dir=new There::Directory();
$dir->update($passid, $clr, "hakusano ja"); 

my $newphrase = "kekkulikuu ja diipadaapa";
ok($api->change_passphrase($clr, $pass, $newphrase), "Changed passphrase");
ok($api->check_passphrase($clr, $newphrase), "The new phrase checks out");
#local $ENV{PATH}="/bin";
#warn `ls -laR $tempdir`;

my $yay=$api->get_password( $clr, $passid, $newphrase );
ok($yay, "still got a password out");
is($yay->latest(), $newpass, "it was still readable!");


ok(${^TAINT}, "Please make your code -T -compatible.");
