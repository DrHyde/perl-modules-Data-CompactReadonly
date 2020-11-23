package Data::CROD::Scalar;

use warnings;
use strict;
use base 'Data::CROD::Node';

sub _init {
    my($class, %args) = @_;
    my $parent = $args{parent};
    
    my $word = $parent->_bytes_at_current_offset($class->_num_bytes());
    return $class->_decode_word($word);
}

sub _decode_word {
    my($class, $word) = @_;

    my $value = 0;
    foreach my $byte (split(//, $word)) {
        $value *= 256;
        $value += ord($byte);
    }
    return $value;
}

sub _create {
    my($class, %args) = @_;
    my $word = abs($args{data});

    my $bytes = '';
    while($word) {
        $bytes = chr($word & 0xff).$bytes;
        $word >>= 8;
    }
    # zero-pad if needed
    $bytes = (chr(0) x ($class->_num_bytes() - length($bytes))).$bytes;
    return $bytes;
}

1;
