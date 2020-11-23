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

sub _create {
    my($class, %args) = @_;
    (my $scalar_type = $class) =~ s/Text/Scalar/;
    my $text = $class->_text_to_bytes($args{data});
    return $scalar_type->_create(%args, data => length($text)).
           $text;
}

sub _bytes_to_text {
    my($invocant, $bytes) = @_;
    return decode('utf-8', $bytes);
}

sub _text_to_bytes {
    my($invocant,$text) = @_;
    return encode('utf-8', $text);
}

1;
