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

Data::CROD->create($filename, {});
open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
isa_ok($data = Data::CROD->read($fh), 'Data::CROD::Dictionary::Byte',
    "got a Dictionary::Byte");
is($data->count(), 0, "it's empty");
is($data->_ptr_size(), 1, "pointers are 1 byte");

my $hash = {
    # header                          5 bytes
    # OMGADICT                        1 byte
    # number of elements (in Byte)    1 byte
    # 12 pairs of pointers         #  24 bytes
    float  => 3.14,                #  7 bytes for key, 9 bytes for value
    byte   => 65,                  #  6 bytes for key, 2 bytes for value
    short  => 65534,               #  7 bytes for key, 3 bytes for value
    medium => 65536,               #  8 bytes for key, 4 bytes for value
    long   => 0x1000000,           #  6 bytes for key, 5 bytes for value
    huge   => 0xffffffff1,         #  6 bytes for key, 9 bytes for value
    array  => [],                  #  7 bytes for key, 2 bytes for value 
    dict   => {},                  #  6 bytes for key, 2 bytes for value
    null   => undef,               #  6 bytes for key, 1 byte for value
    # 119 bytes to this point
    text      => 'hi mum!',        #  6 bytes for key, 9 bytes for value (Text::Byte)
    'hi mum!' => 'hi mum!',        #     free!!! storage
    # the last element in the hash, cos its key sorts last
    zzlongtext => 'z' x 300        # 12 bytes for key, 303 for value (Text::Short)
    # 457 bytes total
};
Data::CROD->create($filename, $hash);
open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
isa_ok($data = Data::CROD->read($fh), 'Data::CROD::Dictionary::Byte',
    "got a Dictionary::Byte");
is($data->count(), 12, "12 entries");
is($data->_ptr_size(), 1, "pointers are 1 byte");
is($data->element('float'),      3.14,        "read a Float");
is($data->element('byte'),       65,          "read a Byte");
is($data->element('short'),      65534,       "read a Short");
is($data->element('medium'),     65536,       "read a Medium");
is($data->element('long'),       0x1000000,   "read a Long");
is($data->element('huge'),       0xffffffff1, "read a Huge");
is($data->element('null'),       undef,       "read a Null");
is($data->element('text'),       'hi mum!',   "read a Text::Byte");
is($data->element('hi mum!'),    'hi mum!',   "read the same text again (reused)");
is($data->element('zzlongtext'), 'z' x 300,   "read a Text::Short");
isa_ok($embedded_array = $data->element('array'), 'Data::CROD::Array::Byte',
    "read an array from the Dictionary");
is($embedded_array->count(), 0, "array is empty");
isa_ok(my $embedded_dict = $data->element('dict'), 'Data::CROD::Dictionary::Byte',
    "read a dictionary from the Dictionary");
is($embedded_dict->count(), 0, "dict is empty");
is((stat($filename))[7], 457, "file size is correct");

fail("FIXME add tests for non-ASCII keys and values; caching of the same; numeric keys");
fail("FIXME add more data after zzlongtext to force a pointer overflow");
fail("FIXME add tests for absurd data structures");

done_testing;
