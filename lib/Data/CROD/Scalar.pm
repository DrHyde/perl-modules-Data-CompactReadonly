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
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);

    print $fh $class->_type_byte_from_class().
              $class->_get_bytes_from_word(abs($args{data}));
}

sub _get_bytes_from_word {
    my($class, $word) = @_;
    return $class->__get_bytes_from_word($word, $class->_num_bytes());
}

sub __get_bytes_from_word {
    my($class, $word, $num_bytes) = @_;

    my $bytes = '';
    while($word) {
        $bytes = chr($word & 0xff).$bytes;
        $word >>= 8;
    }
    # zero-pad if needed: guarded by an 'if' in case we're going
    # to blow a pointer over size - that error will be caught when
    # we try to seek to it to write the data it points to
    $bytes = (chr(0) x ($num_bytes - length($bytes))).$bytes
        if(length($bytes) < $num_bytes);

    return $bytes;
}

1;
