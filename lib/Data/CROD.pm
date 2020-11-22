package Data::CROD;

use warnings;
use strict;

use Data::CROD::Node;

# Yuck, semver. I give in, the stupid cult that doesn't understand
# what the *number* bit of *version number* means has won.
our $VERSION = '0.0.0';

=head1 NAME

Data::CROD

=head1 DESCRIPTION

A Compact Read Only Database that consumes very little memory. Once created a
database can not be practically updated except by re-writing the whole thing.
The aim is for random-access read performance to be on a par with L<DBM::Deep>
and for files to be much smaller.

=head1 METHODS

=head2 create

Not yet implemented

=head2 read

Takes a single argument, which is a filename or an already open file handle. If
a filehandle, the current file pointer should be at the start of the database
(not necessarily at the start of the file; the database could be in a
C<__DATA__> segment) and B<must> have been opened in "just the bytes ma'am"
mode.

It is a fatal error to pass in a filehandle which was not opened correctly or
the name of a file that can't be opened or which doesn't contain a valid database.

Returns the "root node" of the database. If that root node is a number, some
piece of text, or Null, then it is decoded and the value returned. Otherwise an
object representing an Array or a Dictionary is returned.

=head1 DATA TYPES

=head2 SCALAR TYPES

=head3 Integer

These are internally 1, 2, 3, 4, and 8 byte words, but in practice you will
just see them as integers.

=head3 Float

A floating point number.

=head3 Null

Equivalent to C<undef>

=head3 Text

A string of Unicode characters.

For complicated internals reasons this is actually implemented as a Collection
type, but you'll never see that :-)

=head2 COLLECTION TYPES

You will see these types as objects, which implement the following methods:

=over

=item count

The number of elements in the Collection

=item indices

A list of all the indices in the Collection. Note that this may be an expensive
operation for Dictionary objects.

=item element

Takes an index (either a number for Arrays or some text for Dictionaries)
argument and looks up the associated value. It is a fatal error to try to look
up something that doesn't exist. The value can of course be of any type,
including embedded Arrays and Dictionaries. Circular references are permitted -
an Array or Dictionary can contain itself.

=item id

A unique id for this collection within the file. Use this for spotting circular
references, as you won't be able to use C<refaddr()>.

=back

The collection types are:

=head3 Array

An array, 0-based. You access elements by asking for, eg C<...-E<gt>element(37)>.

=head3 Dictionary

An associative array, or hash, although the implementation does not use
hashing. You access elements by asking for, eg C<...-E<gt>element('horse')>.

=head2 UNSUPPORTED PERL TYPES

Globs, Regexes, References (except to Arrays and Dictionaries)

=cut

sub create {
    my($class, %args) = @_;

    $args{version} ||= 0; # default to latest available?

    # return $class->create(file => $args{file}, data => $args{data});
}

sub read {
    my($class, $file) = @_;
    my $fh;
    if(ref($file)) {
        $fh = $file;
        my @layers = PerlIO::get_layers($fh);
        if(grep { $_ !~ /^(unix|perlio|scalar)$/ } @layers) {
            die(
                "$class: file handle has invalid encoding [".
                join(', ', @layers).
                "]\n"
            );
        }
    } else {
        open($fh, '<', $file) || die("$class couldn't open file $file: $!\n");
        binmode($fh);
    }
    
    my $original_file_pointer = tell($fh);

    read($fh, my $header, 5);
    (my $byte5) = ($header =~ /^CROD(.)/);
    die("$class: $file header invalid: doesn't match /CROD./\n") unless(length($byte5));

    my $version  = (ord($byte5) & 0b11111000) >> 3;
    my $ptr_size = (ord($byte5) & 0b00000111) + 1;
    die("$class: $file header invalid: bad version\n") if($version == 0b11111);

    return Data::CROD::Node->_init(file_format_version => $version, ptr_size => $ptr_size, fh => $fh, db_base => $original_file_pointer);
}

1;
