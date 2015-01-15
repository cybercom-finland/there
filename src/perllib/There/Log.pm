package There::Log;
use Sys::Syslog ();
use There::Conf;

use Object::Generic;
use base qw/Object::Generic/;

sub new
{
  my ($class, @args) = @_;
  my $conf = new There::Conf;
  my $self = {
	      facility => $conf->syslog_facility(),
	      ident    => $conf->syslog_ident(),
	      conf     => $conf,
	      @args,
	     };
  bless $self, $class;
  
  Sys::Syslog::openlog($self->ident(), "pid", $self->facility()) or exit 0xee;

  return $self;
}

sub syslog
{
  my ($self, $priority, $format, @args) = @_;
  
  return if ($priority =~ /^debug$/i and ! $self->conf()->debug()); 
  Sys::Syslog::syslog($priority, $format, @args);
}

1;
