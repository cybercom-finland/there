package There::Storage;

use strict;
use There::Conf;

sub new
{
    my ($class) = @_;
    my $conf = new There::Conf;

    my $module = $conf->storage();
    eval "require $module";
    if($@)
    {
	warn "$@";
	return undef;
    }
    return $module->new();
}

1;
