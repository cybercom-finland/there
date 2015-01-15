package There::UI::BetterListbox;

use Curses::UI::Listbox ();
use Curses::UI::Common ();

use base "Curses::UI::Listbox";


sub text_chop 
{
  return $_[1];
}

sub origlabels 
{
  my ($self, $origlabels) = @_;
  if(defined($origlabels))
  {
    $self->{-origlabels} = $origlabels;
  }
  return $self->{-origlabels};
}

42;
