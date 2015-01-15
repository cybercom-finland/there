package There::Algo::Kontti;
use strict;

=head1 NAME 

There::Algo::Kontti

=head1 SYNOPSIS

  use There::Algo::Kontti;

  my $frederik = new There::Algo::Kontti;
  my $mother = new There::Algo::Kontti;
  print $mother->decrypt($frederik->encrypt("Anna pusu");

=cut

sub new
{
    my ($class, $mode) = @_;

    my $self = {
		
    };
    bless $self, $class;

    return $self;
}

sub encrypt
{
    my ($self, $key, $string) = @_;

    my @words = split/(\s+)/,$string;

    my $ciphertext = '';
  KONASANTTI:
    foreach my $word (@words)
    {
      if($word =~ /^[^aeiouyåäö]*$/)
      {
	# konaväli santti koi tantti kokaaliton vontti kona santti
	$ciphertext.= $word;
	next KONASANTTI;
      }
      die "Kosta ontti kokaali vontti."
	unless ($word =~ m/([^aeiouyåäö]*[aeiouyåäö])/i);
      my($start, $end) = ($1, $' );       #'); # moi emacs!
      my $ko = "ko";
      my $ntti = "ntti";
      if(uc($word) eq $word)
      {
	$ko = 'KO';
	$ntti = 'NTTI';
      }
      elsif(ucfirst($start) eq $start)
      {
	$ko = 'Ko';
	$start = lcfirst($start);
      }

      $ciphertext .= "${ko}${end} ${start}${ntti}";
    }

   return $ciphertext;
}

sub decrypt
{
    my ($self, $key, @args) = @_;
    
    my $ciphertext = shift @args; 
    
    my $text = $ciphertext;
    $text =~ s/\b(ko)(\S*) (\S+)ntti\b/($1 eq 'Ko'
					?ucfirst$3:$3).$2/gei;

    return $text;
}

1;
