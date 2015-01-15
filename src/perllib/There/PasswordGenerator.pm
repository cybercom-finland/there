package There::PasswordGenerator;

use Crypt::Random;

sub gimme8
{
  my $not_these = join "", map chr, 0..255;
  $not_these =~ y/abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRTUVWXYZ2346789//d;

  my $r = Crypt::Random::makerandom_octet (Strength => 1,
					   Length   => 8,
					   Skip     => $not_these,
					  ); 
  warn "Could not generate password" unless defined $r;
  warn "Panique! The password is not 8 characters long" unless(length($r)==8);
  
  return $r;
}

sub gimme16
{
  my $not_these = join "", map chr, 0..255;
  $not_these =~ y/abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRTUVWXYZ2346789//d;

  my $r = Crypt::Random::makerandom_octet (Strength => 1,
					   Length   => 16,
					   Skip     => $not_these,
					  ); 
  warn "Could not generate password" unless defined $r;
  warn "Panique! The password is not 16 characters long" unless(length($r)==16);
  
  return $r;
}
42;
