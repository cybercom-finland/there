package There::Directory;

use strict;
use Object::Generic;
use base qw/Object::Generic/;

use There::Conf;
use There::Log;
use IO::Dir;
use IO::File;
use There::Directory::Item;

sub new
{
  my ($class) = @_;
  return bless {log => new There::Log()}, $class;
}

sub update
{
  my ($self, $id, $clearance, $searchstring) = @_;

  my $conf = new There::Conf;
  my $filename = $conf->therepath() . "/" . $conf->directory();

  my @filelines = ();
  my $lineno = 0;
  my ($near, $hit) = ();
  if(my $file = new IO::File($filename, O_RDONLY))
  {
    local $\ = undef;

    while(<$file>)
    {
      $lineno++;
      chomp;
      push @filelines, $_;
      my $item = new There::Directory::Item($_);

      next if $item->is_comment($_);  # comments and empty lines are not searched 

      #my ($xid, $cl, $str) = $item->deserialize();
      if(($id eq $item->id()) && ($clearance eq $item->clearance()))
      {
	$hit = $lineno;
#	print "hit=$hit\n";
      }
      elsif($id eq $item->id())
      {
	next if($near and ($item->clearance() gt $clearance));
	$near = $lineno - ($item->clearance() gt $clearance); # golf!
#	print "near=$near\n";
      }
    }
    $file->close();
  }
  else
  {
     $self->log()->syslog("crit","There is nothing there: '$filename': $! (ignore this warning if you are running for the first time)");
  }

  my $newitem = new There::Directory::Item($id,$clearance,$searchstring);
  if($hit)
  {
    $filelines[$hit-1]= $newitem->serialize();
  }
  elsif(defined $near)
  {
    splice(@filelines, $near, 0, $newitem->serialize());
  }
  else
  {
    push @filelines, $newitem->serialize();
  }

  my $file = new IO::File($filename, O_CREAT|O_RDWR|O_TRUNC) or die "$!";

  local $\ = "\n";
  print $file $_ for @filelines;
 
  $file->close();
}

=head2 search($searchstring, [$searchstring, ...])

Arguments:
  $searchstring - a string containing a search term

Returns:
  a reference to a list of There::Directory::Item objects
  (which is empty if there were no matches)
  undef, if somebody implements error checking and there is an error.

The returned objects will match() all the searchstrings.

=cut

sub search
{
  my $self = shift;
  return $self->clearance_search("", @_);
}

=head2 clearance_search($clearance, $searchstring, [$searchstring, ...])

Arguments:
  $clearance    - the name of the clearance
  $searchstring - a string containing a search term

Returns:
  a reference to a list of There::Directory::Item objects
  (which is empty if there were no matches)
  undef, if somebody implements error checking and there is an error.

The returned objects will match() all the searchstrings, and they are 
accessible with the given clearance.

=cut

sub clearance_search
{
  my ($self, $clearance, @searchterms) = @_;
  $clearance = '' unless defined $clearance;

  my $conf = new There::Conf;
  my $filename = $conf->therepath() . "/" . $conf->directory();
  $self->log()->syslog("debug","reading directory '$filename'");

  my $file = new IO::File($filename, "<");
  if(!$file)
  {
      $self->log()->syslog("info","There is nothing there: '$filename': $! (ignore this warning if you are running for the first time)");
      return [];
  }

  my @stuff = ();

 ITEM:
  while(<$file>)
  {
    chomp;
    my $item = new There::Directory::Item($_);
    next if $item->is_comment();
    next if ($clearance and ($clearance ne $item->clearance()));

    foreach my $searchterm (@searchterms) 
    {
        next if(!defined($searchterm) or ($searchterm eq ""));
	if(! $item->match($searchterm))
	{
	    next ITEM;
	}
    }
    push @stuff, $item;
  }
  $file->close();
  return \@stuff;
}

sub get_entry
{
  my ($self, $clearance, $id) = @_;
  return unless(defined($self) and defined($clearance) and defined($id));

  my $found = $self->clearance_search($clearance, 
				      qr/^\s*\Q$id\E\s*\|\s*\Q$clearance\E\s*\|/);
  if(scalar @$found > 1)
  {
    die "more than one entry found. argh."
  }
  return unless(scalar @$found);
  return $found->[0];
}

1;
