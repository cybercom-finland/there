package There::Algo::Rot;
use strict;

=head1 NAME 

There::Algo::Rot

=head1 SYNOPSIS

  use There::Algo::Rot;

  my $cipher = new There::Algo::Rot("up/dn");
  print $cipher->encrypt("poliisiauto, musta (vm -69)");

  my $caesar = new There::Algo::Rot("13");
  print $caesar->decrypt("Prgrehz prafrb, Pneguntvarz rffr qryraqnz");

=cut

sub new
{
    my ($class, $mode) = @_;
    
    $mode = "13" unless defined $mode;

    my $self = {
	algoname => "Rot",
	mode => $mode
    };
    bless $self, $class;

    return $self;
}

sub encrypt
{
    my ($self, $key, $string) = @_;
    if($self->mode() eq "up/dn")
    {
	$string = reverse $string;
	$string =~ y/pdunqbmwMW967LE3AV(){}[]<>',aev^/dpnubqwmWM69L73EVA)(}{][><,'ea^v/;
	return $string;
    }
    if($self->mode() =~ /^-?\d+$/)
    {
	my $offset = $self->mode();
	my @alphabet = ("a".."z");

	$offset %= @alphabet;
	$offset = @alphabet - $offset if $offset < 0;

	my $alphastring = join "", @alphabet;
	my $replacement = join "", (@alphabet[$offset .. $#alphabet], 
				    @alphabet[0 .. $offset -1]); 
	$alphastring .= uc $alphastring;
	$replacement .= uc $replacement;
	my $operation= "\$string =~ y/$alphastring/$replacement/";
#	print $operation;
	eval $operation;
	return $string;
    }
    return $string;
}

sub decrypt
{
    my ($self, $key, @args) = @_;

    if($self->mode() =~ /^-?\d+$/)
    {
	$self->mode(-$self->mode());
	my $result = $self->encrypt($key, @args);
	$self->mode(-$self->mode());
	return $result;
    }
    # this is a write only module, _you_ figure it out!
    return $self->encrypt($key, @args);
}

sub mode
{
    my($self, @args) = @_;
    $self->{'mode'}=$args[0] if @args;
    return $self->{'mode'};
}

1;
