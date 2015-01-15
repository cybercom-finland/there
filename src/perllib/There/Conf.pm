package There::Conf;

use strict;
use AppConfig;
use base qw(AppConfig);

$::There::Conf::cache = undef;

sub clear_cache
{
    $::There::Conf::cache = undef;
    return 1;
}

sub param_error_handler
{
    warn join("\n",@_);
    die;
}

sub new
{
    my ($class, @args) = @_;

    return $::There::Conf::cache if(defined($::There::Conf::cache));

    my $self = AppConfig->new( 
	{
	    CASE   => 0,
	    ERROR  => \&::There::Conf::param_error_handler,
	    GLOBAL => 
	    { 
		DEFAULT  => "<unset>", 
	    },
	}
	);

    bless $self, $class;

    my %untaint =
    (
     therepath => qr/^(.*)$/,
    );

    $self->define("therepath|there|t=s", { DEFAULT => "/data00/there" } );
    $self->define("algofilename=s", { DEFAULT => ".alcometer" } );
    $self->define("passphraseid=s", { DEFAULT => ".passphrase" } );
    $self->define("storage=s", { DEFAULT => "There::Storage::Default" } );
    $self->define("directory|d=s", { DEFAULT => ".directory" } );
    $self->define("syslog_facility|sf=s", { DEFAULT => "local6" } );
    $self->define("syslog_ident|si=s", { DEFAULT => "there" } );
    $self->define("debug|w", { DEFAULT => 0 } );
    $self->define("archivepath|archive|a=s", { DEFAULT => ".archive" } );
    $self->define("clearance|cl=s@", { } );

    for my $f ( '/etc/thererc', $ENV{HOME}.'/.thererc' )
    {
      -f $f and $self->file( $f );
    }

    $self->getopt();

    while(my($key, $regex) = each %untaint)
    {
      if($self->get($key) =~ $regex)
      {
	my $match = $1;
	my $rv = $self->set($key, $match);
# This does not work. Looks like a perl bug.
#	my $rv = $self->set($key, $1);
#	warn "setting $key to $1" if $self->debug();
#	warn "it became '" . $self->get($key) ."' instead (set returned $rv).";
      }
      else
      {
	warn "bad argument for '$key': ". $self->get($key); 
      }
    }

    $::There::Conf::cache = $self;

    unless(-d $self->therepath())
    {
      local $ENV{'PATH'} = "/bin";
      die "ugly path name" unless $self->therepath()=~ m%^([/\w.-]+)$%;
      my $dir = $1;
      
      system("mkdir", "-p", $dir) and die "Directory '$dir' does not exist and cannot be created. (see above)\n";
    }
    return $self;
}

1;
