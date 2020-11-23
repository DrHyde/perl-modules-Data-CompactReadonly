use strict;
use warnings;
no warnings qw(portable overflow);

use File::Temp qw(tempfile);
use Test::More;

use Data::CROD;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CROD->create($filename, undef);
open(my $fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
is(my $data = Data::CROD->read($fh), undef, "can create a Null file");

foreach my $tuple (
    [0x01,                 7],
    [0x0102,               8],
    [0x010203,             9],
    [0x01020304,          10],
    [0xFFFFFFFF0,         14], # Huge, will require zero-padding
    [0x10000000000000000, 14], # too big for a Huge, encoded as Float
) {
    my($value, $filesize) = @{$tuple};
    foreach my $value ($value, -$value) {
        Data::CROD->create($filename, $value);
        open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
        is($data = Data::CROD->read($fh), $value,
            abs($value) == 0x10000000000000000 ? "auto-promoted humungo-Int to a Float" :
                                                 "can create an Int file ($value)"
        );
        is((stat($filename))[7], $filesize, "... file is expected size");
    }
}

# normal size, practically zero, ginormously -ve
foreach my $value (5.1413, 81.72e-50, -1.37e100/3) {
    Data::CROD->create($filename, $value);
    open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
    is($data = Data::CROD->read($fh), $value, "can create a Float file ($value)");
}






# is($data->ptr_size(), 1, "tiny file has pointer size 1");

done_testing;
