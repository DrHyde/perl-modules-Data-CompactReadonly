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

sub _create {
    my($class, %args) = @_;
    die("fell through to Data::CROD::Node::_create when creating a $class\n")
        if($class ne __PACKAGE__);
    my($fh, $ptr_size, $data, $next_free) = @args{qw(fh ptr_size data next_free)};
    $next_free = tell($fh) unless(defined($next_free));

    my $type_class = $class->_type_class(from_data => $data);
    my $type_byte  = $class->_type_byte_from_class($type_class);
    
    print $fh $type_byte;
    print $fh $type_class->_create(
        fh       => $fh,
        ptr_size => $ptr_size,
        data     => $data
    );
}

sub _db_base {
    my $self = shift;
    return $self->_root()->{db_base};
}

sub _node_at_current_offset {
    my $self = shift;

    my $type_class = $self->_type_class(from_byte => $self->_bytes_at_current_offset(1));
    return $type_class->_init(parent => $self, offset => tell($self->_fh()) - $self->_db_base());
}

sub _type_map_from_data {
    my($class, $data) = @_;
    return !defined($data)
             ? 'Scalar::Null' :
           $data =~ /^-?[0-9]+\.[0-9]+(e[+-]?[0-9]+)?$/
             ? 'Scalar::Float' :
           $data =~ /^(-?)([0-9]+)$/ 
             ? do {
                 my $bytes = 1 + int(log($2) / log(256));
                 $bytes == 1 ? 'Scalar::'.($1 ? 'Negative' : '').'Byte' :
                 $bytes == 2 ? 'Scalar::'.($1 ? 'Negative' : '').'Short' :
                 $bytes == 3 ? 'Scalar::'.($1 ? 'Negative' : '').'Medium' :
                 $bytes == 4 ? 'Scalar::'.($1 ? 'Negative' : '').'Long' :
                 $bytes <  9 ? 'Scalar::'.($1 ? 'Negative' : '').'Huge' :
                               'Scalar::Float'
             } :
           die("Can't yet create from '$data'\n");
}

sub _type_byte_from_class {
    my($my_class, $node_class) = @_;
    $node_class =~ /.*::([^:]+)::([^:]+)/;
    my($type, $subtype) = ($1, $2);
    return chr(
        ({ reverse($my_class->_type_by_bits())    }->{$type}    << 6) +
        ({ reverse($my_class->_subtype_by_bits()) }->{$subtype} << 2)
    );
}

sub _type_by_bits {
    (
        0b00 => 'Text',
        0b01 => 'Array',
        0b10 => 'Dictionary',
        0b11 => 'Scalar'
    )
}

sub _subtype_by_bits {
    (
        0b0000 => 'Byte',      0b0001 => 'NegativeByte',
        0b0010 => 'Short',     0b0011 => 'NegativeShort',
        0b0100 => 'Medium',    0b0101 => 'NegativeMedium',
        0b0110 => 'Long',      0b0111 => 'NegativeLong',
        0b1000 => 'Huge',      0b1001 => 'NegativeHuge',
        0b1010 => 'Null',
        0b1011 => 'Float',
        (map { $_ => 'Reserved' } (0b1100 .. 0b1111))
    )
}

sub _type_map_from_byte {
    my $class   = shift;
    my $in_type = ord(shift());

    my $type        = { $class->_type_by_bits()    }->{$in_type >> 6};
    my $scalar_type = { $class->_subtype_by_bits() }->{($in_type & 0b111100) >> 2};

    die(sprintf("$class: Invalid type: 0b%08b: Reserved\n", $in_type))
        if($scalar_type eq 'Reserved');
    die(sprintf("$class: Invalid type: 0b%08b: length $scalar_type\n", $in_type))
        if($type ne 'Scalar' && $scalar_type =~ /^(Null|Float|Negative)/);
    return join('::', $type, $scalar_type);
}

sub _type_class {
    my($class, $from, $in_type) = @_;
    my $map_method = "_type_map_$from";
    my $type_name = "Data::CROD::".$class->$map_method($in_type);
    eval "use $type_name";
    return $type_name;
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
