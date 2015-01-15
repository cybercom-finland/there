#!/usr/bin/perl -Tw

use Test::More tests => 87;

use lib "src/perllib";
use_ok("There::Algo::AES");

my $cipher = new There::Algo::AES();
ok( defined $cipher, "new() returned something");

#ok($cipher->encrypt(0x95A8EE8E89979B9EFDCBC6EB9797528D432DC26061553818EA635EC5D5A7727E, 0x110A3545CE49B84BBB7B35236108FA6E) == 0x2F9CFDDBFFCDE6B9F37EF8E40D512CF4, "wikipedia test case");

my $key = "95A8EE8E89979B9EFDCBC6EB9797528D432DC26061553818EA635EC5D5A7727E";
my $ciphered = "2F9CFDDBFFCDE6B9F37EF8E40D512CF4";
my $deciphered = "110A3545CE49B84BBB7B35236108FA6E";
my $input = "4EC137A426DABF8AA0BEB8BC0C2B89D6";
my $iv="\0"x16;
map { $_ = pack("H*", $_) } ($input, $key, $ciphered, $deciphered);

my $debug = "";
ok( ($debug = $cipher->_encrypt($iv, $key, $input)) eq $ciphered, "wikipedia test case for the block cipher encryption");
#print unpack ("H*",$_) for( $debug, $ciphered );

ok( ($debug = $cipher->_decrypt($iv, $key, $input)) eq $deciphered, "wikipedia test case for block cipher decryption");
#print unpack ("H*",$_) for( $debug, $deciphered );

ok( ($debug = $cipher->_encrypt("X"x16, $key, $input)) ne $ciphered, "wrong IV must return wrong result");
#print unpack ("H*",$_) for( $debug, $ciphered );

ok( ($debug = $cipher->_encrypt($iv, "Y"x32, $input)) ne $ciphered, "wrong key must return wrong result");
#print unpack ("H*",$_) for( $debug, $ciphered );


ok($cipher->_cbc_cts("1234567890abcdefghijklmnopqrstuv", 10) eq "ghijklmnopqrstuv123456", "_cbc_cts manipulation seems to work");


ok("" eq $cipher->decrypt("avain", $cipher->encrypt("avain", "")),
   "empty message encrypt+decrypt");

ok("" eq $cipher->decrypt("", $cipher->encrypt("", "")),
   "empty message encrypt+decrypt with empty key");

ok("pommi" eq $cipher->decrypt("avain", $cipher->encrypt("avain", "pommi")),
   "very short message encrypt+decrypt");

my $msg = "this string is over 16 bytes long";
ok($msg eq $cipher->decrypt("avain", $cipher->encrypt("avain", $msg)),
   "regular message encrypt+decrypt");

my @collected = ();

foreach $mode (0..10)
{   
    undef $mode;
    my $dada = "";
    my $i;
    my $len = int rand(6000);
    $len+=4; # Zero length message fails sanity check because it will 
             # decrypt correctly even with a wrong key. Same may happen
             # with decreasing probability for other very short messages.
             # Let's be happy with 6000 * 2**32 against false positives.
    for($i=0;$i<$len;$i++)
    {
	$dada .= chr int rand(256);
    }
    ok(length($dada)==$len, "test message initialized more or less correctly");

    my $randkey = "";
    my $keylen = 1+int rand(100);
    for($i=0;$i<$keylen;$i++)
    {
	$randkey .= chr int rand(256);
    }
    ok(length($randkey)==$keylen, "test key initialized more or less correctly");

    my $ciphered = $cipher->encrypt($randkey, $dada);

    ok($cipher->decrypt($randkey, $ciphered) eq $dada,
       "random key (length $keylen) crypt+decrypt, message length $len");
       
    ok($cipher->decrypt("", $ciphered) ne $dada,
       "empty key decrypt should fail");
    push @collected, $ciphered;
}

my $howmany = 0;
my %seen = ();
foreach my $line (@collected)
{
    my @quads = split//,unpack("H*", $line);
    $howmany += @quads;
    
    foreach my $hexchar (@quads)
    {
	$seen{$hexchar}++;
    }
}

$fair_share = $howmany/16;
foreach my $letter (qw/0 1 2 3 4 5 6 7 8 9 a b c d e f/)
{
    ok($seen{$letter} < (2*$fair_share),
       "quad $letter was seen at most twice too often");
    ok($seen{$letter} > ($fair_share/2), "quad $letter was seen at most than twice too seldom");
}

#print $howmany;
