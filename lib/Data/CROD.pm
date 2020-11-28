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

Takes two arguments, the name of file into which to write a database, and some
data. The data can be undef, a number, some text, or a reference to an array
or hash that in turn consists of undefs, numbers, text, references to arrays or
hashes, and so on ad infinitum.

This method may be very slow. It constructs a file by making lots
of little writes and seek()ing all over the place. And it doesn't do anything clever to figure out what pointer size to use, it just tries the shortest first, and then if that's not enough tries again, and again, bigger each time. See L<Data::CROD::Format> for more on pointer sizes.

And this method may eat B<lots> of memory. It keeps a cache of everything it has seen while building your database, so that it can re-use data by just pointing at it instead of writing multiple copies of the same data into the file.

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

=head1 OBJECTS

These are sub-classes of either C<Data::CROD::Array> or C<Data::CROD::Dictionary>.
Both implement the following three methods:

=head2 id

Returns a unique id for this object within the database. Note that circular data
structures are supported, and looking at the C<id> is the only way to detect them.

=head2 count

Returns the number of elements in the structure.

=head2 indices

Returns a list of all the available indices in the structure.

=head2 element

Takes a single argument, which must match one of the values that would be returned
by C<indices>, and returns the associated data.

If the data is a number, Null, or text, the value will be returned directly. If the
data is in turn another array or dictionary, an object will be returned.

=head2 exists

Takes a single argument and tell you whether an index exists for it. It will still
die if you ask it fomr something stupid such as a floating point array index or
a Null dictionary entry.

=head1 UNSUPPORTED PERL TYPES

Globs, Regexes, References (except to Arrays and Dictionaries)

=cut

sub create {
    my($class, $file, $data) = @_;

    my $version = 0;

    PTR_SIZE: foreach my $ptr_size (1 .. 8) {
        my $byte5 = chr(($version << 3) + $ptr_size - 1);
        open(my $fh, '>:unix', $file) || die("Can't write $file: $! \n");
        print $fh "CROD$byte5";
        my $already_seen = {};
        eval {
            Data::CROD::Node->_create(
                fh           => $fh,
                ptr_size     => $ptr_size,
                data         => $data,
                already_seen => $already_seen
            );
        };
        if($@ && index($@, Data::CROD::Node->_ptr_blown()) != -1) {
            next PTR_SIZE;
        } elsif($@) { die($@); }
        last PTR_SIZE;
    }
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
    die("$class: $file header invalid: doesn't match /CROD./\n") unless(defined($byte5));

    my $version  = (ord($byte5) & 0b11111000) >> 3;
    my $ptr_size = (ord($byte5) & 0b00000111) + 1;
    die("$class: $file header invalid: bad version\n") if($version == 0b11111);

    return Data::CROD::Node->_init(
        ptr_size            => $ptr_size,
        fh                  => $fh,
        db_base             => $original_file_pointer
    );
}

1;
