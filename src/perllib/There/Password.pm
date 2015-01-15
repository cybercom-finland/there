package There::Password;
use strict;
use Object::Generic;
use base qw/Object::Generic/;

sub new
{
    my ($class) = @_;
    my $self = { contents => undef,
                 history => [] };
    return bless $self, $class;
}

sub latest
{
    my ($self) = @_;
    my $contents = $self->contents();

    my @revisions = ();
    foreach my $row (split "\n", $contents)
    {
	next if $row =~ /^\s*$/;
	next if $row =~ /^\s*#/;
	push @revisions, $row;
    }

    return undef unless @revisions;

    my $latest_rev = [sort(@revisions)]->[-1];
    if($latest_rev =~ /^\s*[0-9-]+\s(.*)/)
    {
      my $latest = $1;
      return $latest;
    }
    else
    {
      return undef;
    }
}

sub get_all
{
    my ($self) = @_;
    return $self->contents();
}

sub latest_serial
{
    my ($self) = @_;
    return "" unless @{$self->history()};
    my $latest = $self->history()->[-1];
    $latest =~ /^(\S*)\s/;
    return $1;
}

sub serialize
{
    my ($self) = @_;
    return $self->contents();
}

sub deserialize
{
    my ($self, $stuff) = @_;

    $self->history( [ grep ! m/^\s*(#|$)/, sort split /\n/, $stuff ] );
    $self->contents($stuff);
    return 1;
}

sub reboot
{
    my ($self) = @_;
    $self->deserialize($self->serialize());
}

sub change
{
    my ($self, $new) = @_;
    my $blamehim = getlogin();
    my $old = $self->contents() || "";
    $self->contents($old . "# Changed by $blamehim\n". $self->generate_serial() . " $new\n");
    $self->reboot();
}

sub generate_serial
{
    my ($self) = @_;

    my($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime;
    my $serial = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $day);

    my $latest = $self->latest_serial();
    if($latest =~ m/^$serial/)
    {
	$latest =~ s/$serial-?//;
	$latest = $latest ? $latest+1 : 1;
	die "Welcome back tomorrow." if $latest > 9;
	$serial .= "-$latest";
    }
    return $serial;
}


1;
