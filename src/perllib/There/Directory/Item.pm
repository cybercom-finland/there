package There::Directory::Item;

use Object::Generic;
use base qw/Object::Generic/;

sub new 
{
    my ($class, @args) = @_;

    my $self = {
	line => undef
    };

    bless $self, $class;

    if(@args == 1)
    {
	$self->line(@args);
    }
    elsif(@args == 3)
    {
	$self->line(sprintf("%10s | %10s | %s", @args));
    }
    else
    {
	warn "invalid number of arguments.";
	return undef;
    }
    return $self;
}

sub is_comment
{
    my ($self) = @_;
    return $self->line() =~ m/^\s*(#.*|)$/;
}

sub serialize
{
    my ($self) = @_;
    return $self->line();
}

sub deserialize
{
    my ($self) = @_;

    return () if $self->is_comment();
    my ($id, $cl, $blah) = split(/\|/, $self->line(), 3);
    $id =~ s/\s*//g;
    $cl =~ s/\s*//g;
    substr($blah,0,1,''); 
    return($id, $cl, $blah);
}

sub id
{
    my ($self) = @_;
    return ($self->deserialize())[0];
}

sub clearance
{
    my ($self) = @_;
    return ($self->deserialize())[1];
}

sub searchstring
{
    my ($self) = @_;
    return ($self->deserialize())[2];
}

sub match
{
  my ($self, $searchstring) = @_;
  $searchstring = ".*" if $searchstring eq "";
  return $self->line() =~ m/$searchstring/;
}

1;
