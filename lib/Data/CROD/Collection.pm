package Data::CROD::Collection;

use warnings;
use strict;
use base 'Data::CROD::Node';

use Scalar::Util qw(blessed);
use Data::CROD::Scalar;

sub _numeric_type_for_length {
    my $invocant = shift();
    (my $class = blessed($invocant) ? blessed($invocant) : $invocant) =~ s/(Text|Array|Dictionary)/Scalar/;
    return $class;
}

sub count {
    my $self = shift;
    $self->_seek($self->_offset());
    return $self->_numeric_type_for_length()->_init(parent => $self->_parent());
}

sub id {
    my $self = shift;
    return $self->_offset();
}

sub _scalar_type_bytes {
    my $self = shift;
    return $self->_numeric_type_for_length()->_num_bytes();
}

sub _encode_ptr {
    my($class, %args) = @_;
    return Data::CROD::Scalar->__get_bytes_from_word(
        $args{pointer}, 
        $args{ptr_size}
    );
}

sub _decode_ptr {
    goto &Data::CROD::Scalar::_decode_word;
}

1;
