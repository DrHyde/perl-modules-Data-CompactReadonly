package Data::CROD::Node;

use warnings;
use strict;

use Fcntl qw(:seek);

# assumes the $fh is pointing at the first data byte, having just read the header
sub _init {
    my($class, %args) = @_;
    my $self = bless(\%args, $class);
    return $self->_node_at_current_offset();
}

sub _db_base {
    my $self = shift;
    return $self->_root()->{db_base};
}

sub _node_at_current_offset {
    my $self = shift;

    my $type_class = $self->_type_class($self->_bytes_at_current_offset(1));
    eval "use $type_class";
    return $type_class->_init(parent => $self, offset => tell($self->_fh()) - $self->_db_base());
}

sub _type_map {
    my $class   = shift;
    my $in_type = ord(shift());

    my $type = {
        0b00 => 'Text',
        0b01 => 'Array',
        0b10 => 'Dictionary',
        0b11 => 'Scalar'
    }->{$in_type >> 6};

    my $scalar_type = {
        0b0000 => 'Byte',      0b0001 => 'NegativeByte',
        0b0010 => 'Short',     0b0011 => 'NegativeShort',
        0b0100 => 'Medium',    0b0101 => 'NegativeMedium',
        0b0110 => 'Long',      0b0111 => 'NegativeLong',
        0b1000 => 'Huge',      0b1001 => 'NegativeHuge',
        0b1010 => 'Null',
        0b1011 => 'Float',
        (map { $_ => 'Reserved' } (0b1100 .. 0b1111))
    }->{($in_type & 0b111100) >> 2};

    die(sprintf("$class: Invalid type: 0b%08b: Reserved\n", $in_type))
        if($scalar_type eq 'Reserved');
    die(sprintf("$class: Invalid type: 0b%08b: length $scalar_type\n", $in_type))
        if($type ne 'Scalar' && $scalar_type =~ /^(Null|Float|Negative)/);
    return join('::', $type, $scalar_type);
}

sub _type_class {
    my($class, $in_type) = @_;
    my $type_name = $class->_type_map($in_type);
    return "Data::CROD::$type_name";
}

sub _bytes_at_current_offset {
    my($self, $bytes) = @_;
    read($self->_fh(), my $data, $bytes) ||
        die("$self: sysread failed to read $bytes\n");
    return $data;
}

sub _seek {
    my $self = shift;
    my $to   = shift;
    seek($self->_fh(), $self->_db_base() + $to, SEEK_SET);
}

sub _offset {
    my $self = shift;
    return $self->{offset};
}

sub _parent {
    my $self = shift;
    return exists($self->{parent}) ? $self->{parent} : undef;
}

sub _root {
    my $self = shift;
    while($self->_parent()) { $self = $self->_parent(); }
    return $self;
}

sub _fh {
    my $self = shift;
    return $self->_root()->{fh};
}

sub _file_format_version {
    my $self = shift;
    return $self->_root()->{file_format_version};
}

sub _ptr_size {
    my $self = shift;
    return $self->_root()->{ptr_size};
}

1;
