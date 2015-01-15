package There::UI::BetterPopupmenu;

use Curses::UI;
use Curses::UI::Popupmenu ();
use Curses::UI::Common;
use base "Curses::UI::Popupmenu";

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->set_routine("open-popup", \&open_popup);
    return $self;
}

sub open_popup
{
    my $this = shift;
    my $pre_value = $this->get;

    my %listbox_options = %{$this->{-listbox}};
    foreach my $option ( qw(
			    -values -labels 
			    -selected -wraparound
			   ) ) 
    {    
      $listbox_options{$option} = $this->{$option}
	if defined $this->{$option};
    }

    my $id = '__popupmenu_listbox_$this';
    my $listbox = $this->root->add(
				   $id, 'PopupmenuListbox',
				   -border         => 1,
				   -vscrollbar     => 1,
				   %listbox_options
				  );

    $listbox->set_binding('loose-focus', CUI_ESCAPE());

    # No need to popup if already selected 
    if($pre_value)
    {
	$listbox->do_routine("option-select");
	$listbox->do_routine("loose-focus");	
    }
    else
    {
	$listbox->modalfocus;
    }

    my $post_value = $listbox->get;
    $this->{-selected} = $listbox->{-selected};

    if ((not defined $pre_value and 
             defined $post_value) or 
        (defined $pre_value and
            $pre_value ne $post_value)) {
        $this->run_event('-onchange');
    }

    $this->parent()->focus_next();

    $this->root->delete($id);
    $this->root->draw;

    return $this;
}

sub event_keypress 
{
    $::There::UI::BetterPopupmenu::LAST_KEYPRESS ||= 0;
    $::There::UI::BetterPopupmenu::SEARCH_STRING ||= "";
    my $this = shift;
    my $key = $_[0];
    if($key =~ /^[a-zA-Z0-9]$/) # normal letters trigger a search
    {
	# collect letters to form the search term
	my $now = time();
	my $then = $::There::UI::BetterPopupmenu::LAST_KEYPRESS;
	$::There::UI::BetterPopupmenu::LAST_KEYPRESS = $now;

	if($now > $then + 1) # reset when we are sure that there was a pause of at least 1 sec
	{
	    $::There::UI::BetterPopupmenu::SEARCH_STRING = "";
	}
	my $string = $::There::UI::BetterPopupmenu::SEARCH_STRING .= $key;

	# fetch the options
	my $values = $this->{-values};
#	warn "got a keypress, string is '$string', values are ". join ",", @$values;
	
	foreach(@$values) # if labels are used, search among them instead
	{
	    $_ = $this->{-labels}->{$_} if defined $this->{-labels}->{$_};
	}
#	warn "values are now ". join ",", @$values;

	# do the search
	my $i = 0;
	while($i < scalar @$values)
	{
	    if(substr($values->[$i],0,length($string)) eq $string)
	    {
		$this->{-selected} = $i;
		last;
	    }
	    $i++;
	}

	$this->draw();
    }
    else
    {
	$this->SUPER::event_keypress(@_);
    }
}
42;
