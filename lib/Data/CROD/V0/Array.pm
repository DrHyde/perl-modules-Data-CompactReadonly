package Data::CROD::V0::Array;

use warnings;
use strict;
use base qw(Data::CROD::V0::Collection Data::CROD::Array);

use Data::CROD::V0::TiedArray;

sub _init {
    my($class, %args) = @_;
    my($parent, $offset) = @args{qw(parent offset)};

    my $object = bless({
        parent => $parent,
        offset => $offset
    }, $class);

    if($parent->_tied()) {
        tie my @array, 'Data::CROD::V0::TiedArray', $object;
        return \@array;
    } else {
        return $object;
    }
}

# write an Array to the file at the current offset
sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);
    (my $scalar_type = $class) =~ s/Array/Scalar/;

    # node header
    print $fh $class->_type_byte_from_class().
              $scalar_type->_get_bytes_from_word(1 + $#{$args{data}});

    # empty pointer table
    my $table_start_ptr = tell($fh);
    print $fh "\x00" x $args{ptr_size} x (1 + $#{$args{data}});
    my $next_free_ptr = tell($fh); 

    # write a pointer to each item in turn, and if necessary also write
    # item, which can be of any type
    foreach my $index (0 .. $#{$args{data}}) {
        my $this_data = $args{data}->[$index];
        $class->_seek(%args, pointer => $table_start_ptr + $index * $args{ptr_size});
        if(my $ptr = $class->_get_already_seen(%args, data => $this_data)) {
            print $fh $class->_encode_ptr(%args, pointer => $ptr);
        } else {
            print $fh $class->_encode_ptr(%args, pointer => $next_free_ptr);
            $class->_seek(%args, pointer => $next_free_ptr);
            Data::CROD::V0::Node->_create(%args, data => $this_data);
            $next_free_ptr = tell($fh);
        }
    }
}

sub exists {
    my($self, $element) = @_;
    eval { $self->element($element) };
    if($@ =~ /out of range/) {
        return 0;
    } elsif($@) {
        die($@);
    } else {
        return 1;
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
