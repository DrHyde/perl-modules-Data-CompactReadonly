use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use Data::CROD;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CROD->create($filename, undef);
open(my $fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
is(my $data = Data::CROD->read($fh), undef, "can create a Null file");

# normal size, practically zero, ginormously -ve
foreach my $value (5.1413, 81.72e-50, -1.37e100/3) {
    Data::CROD->create($filename, $value);
    open($fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
    is($data = Data::CROD->read($fh), $value, "can create a Float file ($value)");
}






# is($data->ptr_size(), 1, "tiny file has pointer size 1");

done_testing;
