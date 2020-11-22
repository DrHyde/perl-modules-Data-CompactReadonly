package Data::CROD::Text;

use warnings;
use strict;
use base 'Data::CROD::Collection';

use Encode qw(encode decode);

sub _init {
    my($class, %args) = @_;
    my($parent, $offset) = @args{qw(parent offset)};

    my $length = $class->_numeric_type_for_length()->_init(parent => $parent, offset => $offset);
    my $value  = $class->_bytes_to_text($parent->_bytes_at_current_offset($length));

    return $value;
}

sub _bytes_to_text {
    my($invocant, $bytes) = @_;
    return decode('utf-8', $bytes);
}

1;
