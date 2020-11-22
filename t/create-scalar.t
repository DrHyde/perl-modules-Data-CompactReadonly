use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use Data::CROD;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CROD->create($filename, undef);
open(my $fh, '<:unix', $filename) || die("Can't read $filename: $!\n");
is(my $data = Data::CROD->read($fh), undef, "can create a Null file");
# is($data->ptr_size(), 1, "tiny file has pointer size 1");

done_testing;
