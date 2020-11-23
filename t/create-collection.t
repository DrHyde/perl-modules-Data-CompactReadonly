use strict;
use warnings;
no warnings qw(portable);

use File::Temp qw(tempfile);
use Test::More;

use Data::CROD;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CROD->create($filename, []);
open(my $fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
isa_ok(my $data = Data::CROD->read($fh), 'Data::CROD::Array::Byte',
    "can create an Array::Byte");
is($data->count(), 0, "it's empty");
is((stat($filename))[7], 7, "file size is correct");

my $array = [
    # header                        5 bytes
    # OMGANARRAY                    1 byte
    # number of elements (in Byte)  1 byte
    # 11 pointers                  11 bytes
    0x10000,     # Scalar::Medium,  4 bytes
    undef,       # Scalar::Null,    1 byte
    "apple",     # Text::Byte,      7 bytes
    0x1,         # Scalar::Byte,    2 bytes
    0x100,       # Scalar::Short,   3 bytes 
    3.4,         # Scalar::Float,   9 bytes
    0x12345678,  # Scalar::Long,    5 bytes
    0x100000000, # Scalar::Huge,    9 bytes
    0x100000000, # Scalar::Huge, no storage, same as one already in db
    "apple",     # Text::Byte, no storage
    'x' x 256    # Text::Short,     259 bytes
];
Data::CROD->create($filename, $array);
open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
isa_ok($data = Data::CROD->read($fh), 'Data::CROD::Array::Byte',
    "got another Array::Byte");
# yes, 1 byte despite the file being more than 255 bytes long. The
# last thing pointed to starts before the boundary.
is($data->_ptr_size(), 1, "pointers are 1 byte");
is($data->count(), 11, "got a non-empty array");
is($data->element(0), 0x10000,     "read a Medium from the array");
is($data->element(1), undef,       "read a Null");
is($data->element(2), 'apple',     "read a Text::Byte");
is($data->element(3), 1,           "read a Byte");
is($data->element(4), 256,         "read a Short");
is($data->element(5), 3.4,         "read a Float");
is($data->element(6), 0x12345678,  "read a Long");
is($data->element(7), 0x100000000, "read a Huge");
is($data->element(8), 0x100000000, "read another Huge");
is($data->element(9), 'apple',     "read another Text");
is($data->element(10), 'x' x 256,  "read another Text");
is((stat($filename))[7], 317, "file size is correct");

push @{$array}, [], $array;
Data::CROD->create($filename, $array);
open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
isa_ok($data = Data::CROD->read($fh), 'Data::CROD::Array::Byte',
    "got another Array::Byte");
# last item pointed at is too far along for 1 byte pointers.
# TODO alter the order in which things are added to the file so
# that this array can have items after the long text, but they're
# stored before it, so we can keep using short pointers for longer
is($data->_ptr_size(), 2, "pointers are 2 bytes");
is($data->count(), 13, "got a non-empty array");
is($data->element(0), 0x10000,     "read a Medium from the array");
is($data->element(1), undef,       "read a Null");
is($data->element(2), 'apple',     "read a Text::Byte");
is($data->element(3), 1,           "read a Byte");
is($data->element(4), 256,         "read a Short");
is($data->element(5), 3.4,         "read a Float");
is($data->element(6), 0x12345678,  "read a Long");
is($data->element(7), 0x100000000, "read a Huge");
is($data->element(8), 0x100000000, "read another Huge");
is($data->element(9), 'apple',     "read another Text");
is($data->element(10), 'x' x 256,  "read a Text::Short");
isa_ok(my $embedded_array = $data->element(11), 'Data::CROD::Array::Byte',
    "can embed an array in an array");
is($embedded_array->count(), 0, "sub-array is empty");
is($data->element(12)->element(12)->element(11)->id(),
   $embedded_array->id(),
   "circular array-refs work");
# this is:
#   original size +
#   two extra pointers +
#   thirteen for the pointers now being Shorts
#   two for the empty array
is((stat($filename))[7], 317 + 2 + 13 + 2, "file size is correct");

done_testing;
