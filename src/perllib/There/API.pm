package There::API;
use Object::Generic;
use base qw/Object::Generic/;

use There::Conf;
use There::Algo;
use There::Storage;
use There::Password;
use There::Directory;
use There::Directory::Item;

use strict;

=head1 NAME 

There::API - Application programmer's interface to there

=head1 SYNOPSIS

  use There::API;
  my $api = new There::API;


=head1 DESCRIPTION

There::API provides an interface for storing passwords in there.

This module would typically be used by a There::UI module.

=head1 METHODS

=cut

=head2 new

Arguments
  none

returns
  a There::API object

=cut

sub new
{
  my $conf = new There::Conf;
  my $storage = new There::Storage;

  return bless { conf => $conf, storage => $storage }, shift;
}

=head2 get_algorithms()

Arguments:
  none

Returns:
  List of supported algorithms names.

=cut

sub get_algorithms
{
  return There::Algo::get_algorithms();
}

=head2 get_recommended_algorithm()

Arguments:
  none

Returns:
  The name of the algorithm that is recommended for best available
  cryptography.

=cut

sub get_recommended_algorithm
{
  return There::Algo::get_recommended_algorithm();
}

=head2 list_clearances()

Arguments:
  none

Returns:
  List of known clearances

Exceptions:  
  Default storage dies if therepath cannot be opened.

=cut

sub list_clearances
{
  my ($self) = @_;
  unless(defined $self) 
  { 
    die "list_clearances called without object reference";
  }
  return $self->storage()->list_clearances();
}

=head2 _get_algo($clearance)

Arguments:
  $clearance - the name of a clearance level

Returns:
  an object of class There::Algo
  undef, if something goes wrong.

_get_algo tries to figure out which encryption algorithm is used by 
the named clearance, and then loads the appropriate modules via There::Algo

=cut

sub _get_algo
{
  my ($self, $clearance) = @_;
  unless(defined $self) 
  { 
    die "_get_algo called without object reference";
  }
  unless(defined $clearance) 
  { 
    warn "_get_algo called without arguments, bailing out";
    return undef;
  }

  my $algoname = $self->storage()->retrieve($clearance, $self->conf()->algofilename());

  chomp($algoname);
  my $algo = new There::Algo($algoname);
  return $algo;
}

=head2 _get_pass($clearance, $passid, $algo, $passphrase)

Arguments:
  $clearance  - the name of the clearance level
  $passid     - id of the stored password
  $algo       - the encryption object for the clearance
  $passphrase - the encryption key to unlock the storage

Returns:
  a There::Password object, if everything went well
  undef otherwise

_get pass retrieves the requested stored password from there, and decrypts it.

=cut

sub _get_pass
{
  my ($self, $clearance, $passid, $algo, $passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($passid) and
	 defined($algo) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to _get_pass(), bailing out";
    return undef;
  }

  my $pass = new There::Password();

  my $data = $self->storage()->retrieve($clearance, $passid);
  if($data)
  {
    my $decrypted = $algo->decrypt($passphrase, $data);
    $pass->deserialize($decrypted);
    if(defined $pass->latest())
    {
      return $pass;
    }
    else
    {
      warn "Wrong passphrase for clearance '$clearance'.\n";
      # or a corrupted data file. but whatever.
      return undef;
    }
  }
  else
  {
    warn "Could not retrieve password '$passid', clearance '$clearance'. Borked data file?\n";
    return undef;
  }
  # if-else-otherwise
  return undef;
}


=head2 create_clearance($clearance, $algoname, $passphrase)

Arguments:
  $clearance  - name of the new clearance
  $algoname   - name of the encryption algorithm to be used
  $passphrase - passphrase to be used by the algorithm

returns
  1, if everything went fine
  undef otherwise, if returns at all.

Creates a new clearance level in there. Stores the passphrase for 
the clearance on the new clearance level, encrypted using itself.
Runs check_passphrase after, just to be sure.

=cut

sub create_clearance
{
  my ($self, $clearance, $algoname, $passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($algoname) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to create_clearance(), bailing out";
    return undef;
  }

  my $algo = new There::Algo($algoname);
  return undef unless defined($algo);

  # create 

  return undef unless $self->storage()->create_clearance($clearance);

  # store algorithm
  return undef unless $self->storage()->store($clearance, $self->conf()->algofilename(), $algoname);

  my $pass = new There::Password();
  $pass->change($passphrase);
  
  #print "serialized: '".$pass->serialize()."'\n";
  # store passphrase
  return undef unless
    $self->storage()->store($clearance, 
			    $self->conf()->passphraseid(),
			    $algo->encrypt($passphrase, $pass->serialize()));

  unless($self->check_passphrase($clearance, $passphrase))
  {
    warn "STOP! I just created this clearance, but my passphrase does not match! Argh!";
    die "Urgh.";
  }
  return 1;
}

=head2 check_passphrase($clearance, $passphrase)

Arguments:
  $clearance  - name of the clearance
  $passphrase - passphrase for that clearance

Returns:
  1, if the passphrase was correct
  undef, if the passphrase was incorrect
  undef, if there was an error

Checks whether the passphrase is correct for the given clearance.

This happens by trying to decrypt a special password entry automatically 
created by create_clearance().

If the special entry decrypts into the passphrase itself, then the passphrase 
is correct.

Otherwise, the passphrase was incorrect OR there was an error. If the 
algorithm is strong enough, then these cases should be indistinguishable.

NB. do not implement a XOR algorithm. ever. thank you. 

=cut

sub check_passphrase
{
  my($self, $clearance, $passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to check_passphrase(), bailing out";
    return undef;
  }

  my $algo = $self->_get_algo($clearance);
  my $pass = $self->_get_pass($clearance, $self->conf()->passphraseid(), $algo, $passphrase);

  return undef unless defined $pass;

  my $latest = $pass->latest();
  if(defined $latest)
  {
    return 1 if($pass->latest() eq $passphrase);
    return undef; # this _may_ occur in some rare cases.
  }

  warn "unreachable code reached";
  # _get_pass returns undef unless $pass->latest() is defined.
  return undef;
}






=head2 change_passphrase($clearance, $passphrase, $new_passphrase)

Arguments:
  $clearance      - name of the clearance
  $passphrase     - passphrase for that clearance
  $new_passphrase - new passphrase for that clearance

Returns:
  1, if the passphrase was changed
  0, if the passphrase was incorrect
  undef, if there was an error

Changes passphrase for the clearance.

What happens:

  * Check old passphrase
  * Create a temporary clearance with the new passphrase
  * Read all passwords and store them in the temp clearance
  * Swap the temporary clearance with the old one
  * Move the old clearance into archive

What does NOT happen:

  * The passwords are NOT changed
  * The directory is not touched at any point

=cut

sub change_passphrase
{
  my($self, $clearance, $passphrase, $new_passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($passphrase) and
	 defined($new_passphrase))
  {
    warn "undefined parameter passed to change_passphrase(), bailing out";
    return undef;
  }

  return 0 unless $self->check_passphrase($clearance, $passphrase);

  my $algo = $self->_get_algo($clearance);
  my $storage = new There::Storage();

  my $new_clearance = ".tmp-$clearance-$$-".time();
  my $success = $self->create_clearance($new_clearance, $algo->algoname(), $new_passphrase);
  return undef unless $success;

  my $dir = new There::Directory();
  my $items = $dir->clearance_search($clearance, "");
  
  foreach my $item (@$items)
  {
    # warn "DEBUG: converting password ". $item->id();
    my $pass = $self->get_password($clearance, $item->id(), $passphrase);
    unless($pass)
    {
      warn "Clearance was already borked, will not do anything";
      $self->destroy_clearance($new_clearance);
      return undef;
    }

    $storage->store($new_clearance, $item->id(), $algo->encrypt($new_passphrase, $pass->serialize()));
    
    my $doublecheck = $self->get_password($new_clearance, $item->id, $new_passphrase);
    if(! defined($doublecheck) or $pass->latest() ne $doublecheck->latest())
    {
      warn "Double check failed while re-encoding data.";
      $self->destroy_clearance($new_clearance);
      die "Implementation failure";
    }
  } 

  unless($storage->replace_clearance($clearance, $new_clearance))
  {
    warn "Could not change the passphrase";
    die "Implementation error, maybe";
  }
  
  return 1;
}

=head2 store_password($clearance, $passid, $newpass, $passphrase)

=head2 create_password($clearance, $passid, $newpass, $passphrase)

=head2 change_password($clearance, $passid, $newpass, $passphrase)

Arguments:
  $clearance  - name of the clearance level of this password
  $passid     - id for the password to be stored
  $newpass    - the password (in cleartext) to be stored
  $passphrase - passphrase for the clearance

Returns:
  1 - if the password was stored successfully
  0 - if not
  undef if failed to read the password back after successful looking store.

change_password will only work, if the password already exists.

create_password will only work, if the password does not already exists.

store_password will not care. 

=cut

sub create_password
{
  my $self = shift;
  my($clearance, $passid, $newpass, $passphrase) = @_;
  
  unless(defined($self) and 
	 defined($clearance) and
	 defined($passid) and
	 defined($newpass) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to create_password(), bailing out";
    return undef;
  }

  return 0 if $self->storage()->retrieve($clearance, $passid);
  return $self->store_password(@_);
}

sub change_password
{
  my $self = shift;
  my($clearance, $passid, $newpass, $passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($passid) and
	 defined($newpass) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to create_password(), bailing out";
    return undef;
  }
  
  return 0 unless $self->storage()->retrieve($clearance, $passid);
  return $self->store_password(@_);
}

sub store_password
{
  my($self, $clearance, $passid, $newpass, $passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($passid) and
	 defined($newpass) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to store_password(), bailing out";
    return undef;
  }

  unless($self->check_passphrase($clearance, $passphrase))
  {
    warn "Wrong passphrase given for clearance '$clearance'.";
    # or a corrupted file, maybe
    return undef;
  }

  my $algo = $self->_get_algo($clearance);
  unless(defined $algo)
  {
    warn "Could not figure out the algorithm for clearance '$clearance'";
    return undef;
  }

  my $pass = undef;
  if($self->storage()->retrieve($clearance, $passid))
  {
    $pass = $self->_get_pass($clearance, $passid, $algo, $passphrase);
  }
  else
  {
    $pass = new There::Password;
  }

  $pass->change($newpass);
  
  my $data = $pass->serialize();

  unless(defined $data)
  {
    warn "pass->serialize() returned undef. Suicide time.";
    die "Implementation error";
  }

  my $rv =
    $self->storage()->store($clearance,
			    $passid,
			    $algo->encrypt($passphrase, $pass->serialize()));
  unless($rv)
  {
    warn "storage->store failed, something is badly broken.";
    return 0;
  }

  # double check
  my $readback = $self->get_password($clearance, $passid, $passphrase);
  unless(defined $readback)
  {
    warn "I just stored password with id '$passid' on clearance '$clearance',",
      " but cannot find it anymore. Please help!";
    return undef;
  }
  if(defined $readback->latest() and $readback->latest() eq $newpass)
  { 
    # Yay!
    return 1;
  }
  else
  {
    warn "something went horribly wrong: the latest password for ".
      "id '$passid' is not what I just stored there. EVERYBODY PANIC.";
    return undef;
  }
}

=head2 get_password($clearance, $passid, $passphrase)

Arguments:
  $clearance  - name of the clearance
  $passid     - id of the password to retrieve
  $passphrase - passphrase for the clearance

Returns:
  a There::Password object, if successful
  0, if the passphrase seemed incorrect
  undef, unless successful.

=cut

sub get_password
{
  my($self, $clearance, $passid, $passphrase) = @_;

  unless(defined($self) and 
	 defined($clearance) and
	 defined($passid) and
	 defined($passphrase))
  {
    warn "undefined parameter passed to get_password(), bailing out";
    return undef;
  }

  my $algo = $self->_get_algo($clearance);
  return 0 unless $self->check_passphrase($clearance, $passphrase);
  
  my $pass = $self->_get_pass($clearance, $passid, $algo, $passphrase);
  return undef unless($pass);

  my $login = getpwuid($<);
  my $log = new There::Log();
  $log->syslog("INFO", 
	       '"%s" viewed the password "%s" (clearance "%s")',
	       $login, $passid, $clearance);
  return $pass;
}

1;
