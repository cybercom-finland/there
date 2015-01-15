package There::Algo::AES;
use strict;
use Crypt::Rijndael;
use Digest::SHA qw(sha256);

$::There::Algo::AES::DEBUG = 0;

sub new
{
    my ($class) = @_;

    my $self = {
	algoname => "AES",
    };
    bless $self, $class;

    return $self;
}

=head2 encrypt($key, $string)

Arguments:

  $key    - the encryption key
  $string - the string to be encrypted

Returns cipherstring. 
The first 16 bytes of the cipherstring are a random Initialisation Vector 
(salt), the rest are ciphertext blocks produced by AES+CBC+CTS.(see below)

The encryption method used is 256 bit AES (Advanced Encryption Standard), 
which is used in the CBC (Chained Block Cipher) mode. 

If the length of the message string is not a multiple of blocksize (16 bytes),
then CTS (CipherText Stealing) is used to hide the necessary padding.

If the given key is not exactly 32 bytes long, it whill be passed through
SHA-256 (Secure Hash Algorithm) to generate the actual encryption key.

=cut

sub encrypt
{
    my ($self, $key, $string) = @_;

    print("Message: '$string'\n") if $::There::Algo::AES::DEBUG > 1;

    my $len = length($string);
    my $last_block_size = $len % 16;
    my $padding_length = (16-$last_block_size) % 16;
    my $padinki = "\0" x $padding_length;

    print("padding length: $padding_length") if $::There::Algo::AES::DEBUG > 1;

    my $init_vector="";
    $init_vector .= chr(int(rand(256))) for (1..16);

    my $ciphertext = $self->_encrypt($init_vector, 
				     $self->_gimme256($key),
				     $string.$padinki);
    my $cipherstring = $self->_cbc_cts($init_vector.$ciphertext, 
				       $padding_length);
    
    return $cipherstring;
}

sub _cbc_cts
{
    my ($self, $cipherstring, $padding_length) = @_;

    print("before cts  : ", unpack("H*", $cipherstring)) if $::There::Algo::AES::DEBUG > 1;

    return $cipherstring unless $padding_length %= 16;

    # swap the last two blocks and truncate away as many bytes as there 
    # were padding

    my $last_block = substr($cipherstring, -16, 16);
    my $penultimate_block = substr($cipherstring, -32, 16);
    my $truncated_penultimate = substr($penultimate_block, 
				       0, 16-$padding_length);

    substr($cipherstring, -32, 32, $last_block.$truncated_penultimate);

    print("after cts   : ", unpack("H*", $cipherstring)) if $::There::Algo::AES::DEBUG > 1;
    return $cipherstring;
}


sub _de_cbc_cts
{
    my ($self, $key, $cipherstring) = @_;
    print("before dects: ", unpack("H*", $cipherstring)) if $::There::Algo::AES::DEBUG > 1;

    my $last_block_length = length($cipherstring) % 16;
    return $cipherstring unless $last_block_length;
    my $padding_length = 16-$last_block_length;

    # special case: encoded string was shorter than blocksize
    
    # magically, this Just Works: our cipherstring had the IV prepended to
    # to it before we ctsed it, and part that got truncated was a piece of the
    # IV instead of the penultimate block.
    # Now, for the CBC method the IV is just "a ciphertext block that came 
    # before the first actual ciphertext block", so there is no bifference in
    # figuring it out.

    # general case
    my $last_block = substr($cipherstring, 
			    -$last_block_length, 
			    $last_block_length);
    my $penultimate_block = substr($cipherstring, 
				   -(16+$last_block_length), 
				   16);

    # undo a step of CBC mode manually to decrypt the penultimate block only
    my $cipher = Crypt::Rijndael->new($self->_gimme256($key), Crypt::Rijndael::MODE_ECB());
    # remove block cipher
    my $penultimate_no_aes = $cipher->decrypt($penultimate_block);

    # now, use a known plaintext attack: the last $padding_length bytes
    # of the plaintext are known to be zeroes.
    # Use this information to recover the part of the block that was truncated
    # in function _cbc_cts
    
    my $truncated_part = substr($penultimate_no_aes, 
				-$padding_length, $padding_length);
    
    # reattach and restore original order
    substr($cipherstring, -(16+$last_block_length)) = 
	   $last_block.$truncated_part.$penultimate_block;
    print("after dects : ", unpack("H*", $cipherstring)) if $::There::Algo::AES::DEBUG > 1;

    return $cipherstring;
}

sub _encrypt
{
    # internal encryption function, do not use directly.
    # use the underscoreless version instead.
    my ($self, $iv, $key, $string) = @_;
    die "message needs to be padded to multiples of blocksize (16)!"
	if(length($string)%16);
    die "IV length must be exactly 16 bytes!"
	if(length($iv)!=16);
    die "Key length must be exactly 32 bytes!"
	if(length($key)!=32);

    my $len = length($string);
    my $padinki= $len %16 ? "\0"x(16-($len%16)) : "";
    my $shakey = $key;

    my $cipher = Crypt::Rijndael->new($key,
				      Crypt::Rijndael::MODE_CBC());    
    
    $cipher->set_iv($iv);
    return $cipher->encrypt($string.$padinki);
}


sub decrypt
{
    my ($self, $key, $cipherstring) = @_;
    my $orig_cipher_length = length($cipherstring);

    $cipherstring = $self->_de_cbc_cts($key, $cipherstring);

    my $len = length($cipherstring);
    my $mistake = $len%16;
    die "having too much padding($mistake), shouldn't" if($mistake);

    my $iv = substr($cipherstring, 0, 16);
    my $ciphertext = substr($cipherstring, 16);

    my $padded_plaintext = $self->_decrypt($iv, $self->_gimme256($key), $ciphertext);

    my $plaintext_length = $orig_cipher_length - 16;

    my $plaintext = substr($padded_plaintext, 0, $plaintext_length);
    return $plaintext;
}

sub _decrypt
{
    my ($self, $iv, $key, $string) = @_;

    die "message needs to be padded to multiples of blocksize (16)!"
	if(length($string)%16);
    die "IV length must be exactly 16 bytes!"
	if(length($iv)!=16);
    die "Key length must be exactly 32 bytes!"
	if(length($key)!=32);

    my $cipher = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());
    $cipher->set_iv($iv);
    return $cipher->decrypt($string);
}

sub _gimme256
{
    my($self, $string) = @_;
    if(length($string) == 32)
    {
	$string =~ /(.*)/;
	return $1;
    }
    return sha256($string);
}

1;
