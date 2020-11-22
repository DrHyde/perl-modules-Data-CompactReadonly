package Data::CROD::Array;

use warnings;
use strict;
use base 'Data::CROD::Collection';

sub _init {
    my($class, %args) = @_;
    my($parent, $offset) = @args{qw(parent offset)};

    return bless({
        parent => $parent,
        offset => $offset
    }, $class);
}

sub element {
    my($self, $element) = @_;
    no warnings 'numeric';
    die("$self: Invalid element: $element: negative\n")
        if($element < 0);
    die("$self: Invalid element: $element: non-integer\n")
        if($element =~ /[^0-9]/);
    die("$self: Invalid element: $element: out of range\n")
        if($element > $self->count() - 1);

    $self->_seek($self->_offset() + $self->_scalar_type_bytes() + $element * $self->_ptr_size());
    my $ptr = $self->_decode_ptr(
        $self->_bytes_at_current_offset($self->_ptr_size())
    );
    $self->_seek($ptr);
    return $self->_node_at_current_offset();
}

sub indices {
    my $self = shift;
    
    return [] if($self->count() == 0);
    return [(0 .. $self->count() - 1)];
}
1;
