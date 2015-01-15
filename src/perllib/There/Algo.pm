package There::Algo;
use Object::Generic;
use base qw /Object::Generic/;

use strict;

%::There::Algo::algorithms =
(
    'caesar' => {
	module => 'There::Algo::Rot',
	params => [ '1' ],
    },
    'rot13' => {
	module => 'There::Algo::Rot',
	params => [ '13' ],
    },
    'up/dn' => {
	module => 'There::Algo::Rot',
	params => [ 'up/dn' ],
    },
    'kontti' => {
	module => 'There::Algo::Kontti',
	params => [ ],
    },
    'AES' => {
	module => 'There::Algo::AES',
	params => [ ],
    },
);

sub get_algorithms
{
  return keys %::There::Algo::algorithms;
}

sub get_recommended_algorithm
{
  return 'AES';
}

sub new
{
    my ($class, $algoname) = @_;

    my $self = {
	algoname => $algoname,
	algorithm => undef
    };
    bless $self, $class;
    $self->prepare() or return undef;
    return $self;
}

sub prepare
{
    my ($self) = @_;

    my $algoname = $self->algoname();
    my $algoinfo = $There::Algo::algorithms{$algoname}
      or die "No such algorithm ($algoname).";

    my $module = $algoinfo->{'module'};
    my $params = $algoinfo->{'params'};

    eval "require $module";
    die $@ if $@;

    $self->algorithm($module->new(@$params)) or die;
    return 1;
}

sub encrypt
{
  my ($self, $key, $value) = @_;
  return $self->algorithm()->encrypt($key, $value);
}

sub decrypt
{
  my ($self, $key, $value) = @_;
  return $self->algorithm()->decrypt($key, $value);
}

1;
