package There::UI::CookedTextEntry;

use Curses::UI::TextEntry;
use base "Curses::UI::TextEntry";

sub new
{
  my ($class, @args) = @_;
  my %arghash = @args;

  my $onkeypress = sub {};
  if(exists($arghash{"-onkeypress"}))
  {
    $onkeypress = $arghash{"-onkeypress"};
    delete $arghash{"-onkeypress"};
  }
  my $self = $class->SUPER::new(%arghash);
  $self->{"-cooked_on_keypress"} = $onkeypress;
  return $self;
}

sub event_keypress
{
  my $self=shift;
  my $rv = $self->SUPER::event_keypress(@_);
  my $cooked_on_keypress = $self->{"-cooked_on_keypress"};
  &$cooked_on_keypress($self, @_);
  return $rv;
}

2;
