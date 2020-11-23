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

sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);
    (my $scalar_type = $class) =~ s/Array/Scalar/;

    print $fh $class->_type_byte_from_class().
              $scalar_type->_get_bytes_from_word(1 + $#{$args{data}});

    # first write an empty pointer table
    my $table_start_ptr = tell($fh);
    print $fh "\x00" x $args{ptr_size}
        foreach(0 .. $#{$args{data}});
    my $next_free_ptr = tell($fh); 

    foreach my $index (0 .. $#{$args{data}}) {
        my $this_data = $args{data}->[$index];
        $class->_seek(%args, pointer => $table_start_ptr + $index * $args{ptr_size});
        if(my $ptr = $class->_get_already_seen(%args, data => $this_data)) {
            print $fh $class->_encode_ptr(%args, pointer => $ptr);
        } else {
            print $fh $class->_encode_ptr(%args, pointer => $next_free_ptr);
            $class->_seek(%args, pointer => $next_free_ptr);
            Data::CROD::Node->_create(%args, data => $this_data);
            $next_free_ptr = tell($fh);
        }
    }
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
