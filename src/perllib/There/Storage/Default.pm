package There::Storage::Default;

use strict;
use There::Conf;
use IO::Dir;
use IO::File;
use File::Temp;

sub new
{
  my ($class) = @_;
  return bless {}, $class;
}

sub writable
{
  my ($self) = @_;
  
  my $conf = new There::Conf;
  my $path = $conf->therepath();
  
  if(-e $path)
  {
      return 1 if -w _;
      return 0;
  }
  return undef;
}

sub create_clearance
{
  my ($self, $clearance) = @_;

  my $conf = new There::Conf;
  my $path = $conf->therepath() . "/$clearance";
  
  if(-e $path)
  {
    warn "$path already exists.\n";
    return 0;
  }

  mkdir($path) or die $!;
  return 1;
}

sub replace_clearance
{
  my ($self, $clearance, $new_clearance) = @_;

  my $conf = new There::Conf;
  my $path = $conf->therepath() . "/$clearance";
  my $sourcepath = $conf->therepath() . "/$new_clearance";
  
  my $tempdir = File::Temp::tempdir(".thereXXXXX", DIR => $conf->therepath(), CLEANUP => 1);
  my $temppath = "$tempdir/$clearance";
  my $uglyhack = substr($temppath, length($conf->therepath()."/"));

  unless(rename($path, $temppath))
  {
    die "HELP! $!";
  }
  unless(rename($sourcepath, $path))
  {
    die "HELP $!";
  }

  unless($self->destroy_clearance($uglyhack))
  {
    warn "could not make an archive copy!";
    return undef;
  }
  
  return 1;
}

sub destroy_clearance
{
  my ($self, $clearance) = @_;

  my $conf = new There::Conf;
  # there are no slashes in clearance names. lets abuse this!
  my $basename = $clearance;
  $basename =~ s/.*\///; 

  my $path = $conf->therepath() . "/$clearance";
  my $archive = $conf->archivepath();
  unless($archive =~ /^\//)
  {
    $archive = $conf->therepath() ."/". $archive;
  }
  if(! -d $archive)
  {  
    unless(mkdir $archive)
    {
      die "Could not create archive directory, $!";
    }
  }
  my @now = localtime();
  my $today = sprintf("%04d-%02d-%02d", $now[5]+1900, $now[4]+1, $now[3]); 
  my $archivename = File::Temp::tempdir("$today-XXXXX", DIR => $archive);
  unless(rename($path, "$archivename/$basename"))
  {
    warn "could not rename '$path' to '$archivename/$basename': $!";
    return undef;
  }
}

sub list_clearances
{
  my ($self) = @_;

  my $conf = new There::Conf;
  my $path = $conf->therepath();
  
  my $dir = new IO::Dir($path) or die $!;
  
  my @dirs;
  while(defined(my $file = $dir->read()))
  {
    chomp($file);
    next if $file =~ m/^\./;
    next unless $file =~ /^([^\/]+)$/;
    $file = $1;
    if(-d "$path/$file")
    {
      push @dirs, $file;
    }
  }
  $dir->close();
  return @dirs;
}

sub list_keys
{
    my ($self, $clearance) = @_;

    my $conf = new There::Conf;
    my $path = $conf->therepath() . "/$clearance";

    my $dir = new IO::Dir($path);
    unless($dir)
    {
      warn $!;
      return;
    }
    my @files;
    while(defined(my $file = $dir->read()))
    {
	chomp($file);
	next if $file =~ m/^\./;
	if(-f "$path/$file")
	{
	    push @files, $file;
	}
    }
    $dir->close();
    return @files;
}

sub store
{
    my ($self, $clearance, $key, $value) = @_;

    my $conf = new There::Conf;
    my $dir = $conf->therepath() . "/$clearance";

    if($dir =~ m/^(.*)$/)
    {
	$dir = $1;
    }
    else
    {
	warn "Invalid dir '$dir', will not store.";
	return;
    }

    if($key =~ m/^([^\/]+)$/)
    {
	$key = $1;
    }
    else
    {
	warn "Invalid key '$key', will not store.";
	return;
    }

    # IO::File->open does not work for relative paths, known bug:
    # http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=422733
#    my $file = IO::File->new("$dir/$key", ">") or die $!;

    # this uses sysopen internally and thus works.
    my $file;
    unless($file = IO::File->new("$dir/$key", O_CREAT|O_TRUNC|O_RDWR, 0666))
    {
      warn "Could not store $dir/$key";
      die $!;
    }

    # make it work even with '-l'
    local $\ = undef;

    print $file $value or die $!;
    $file->close() or die $!;
    return 1;
}

sub retrieve
{
    my ($self, $clearance, $key) = @_;
    my $conf = new There::Conf;
    my $dir = $conf->therepath() . "/$clearance";

    my $file = new IO::File "$dir/$key", "<";
    return undef unless defined $file;
    local $/ = undef;
    my $value = <$file>;
    $file->close() or die $!;

    return $value;
}

1;
