use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More skip_all => 'not yet implemented';
use Test::Exception;

use Data::CROD;

(undef, my $filename) = tempfile(UNLINK => 1);

Data::CROD->create($filename, [
    [5, 4, 3, 2, 1, 0],
    {
        hash  => { lemon => 'curry' },
        array => [ qw(lemon curry) ],
    },
    'fishfingers'
]);
open(my $fh, '<:unix', $filename) || die("Can't write $filename: $!\n");
my $data = Data::CROD->read($fh);
is($#{$data}, $data->count() - 1, "can de-ref and count elements in an Array");
is($data->[2], 'fishfingers', "can de-ref and retrieve an array element");
is($#{$data->[0]}, $data->element(0)->count(), "those work on nested arrays");
throws_ok { $data->[3] } qr/Argh/, "can't fetch illegal array index";
throws_ok { $data->[1] = 3 } qr/Argh/, "can't write to an array";

throws_ok { $data->[1]->{cow} } qr/Argh/, "can't fetch illegal dict key";
throws_ok { $data->[1]->{hash} = 'pipe' } qr/Argh/, "can't write to a hash";
is($data->[1]->{hash}->{lemon}, 'curry', "can de-ref and retrieve Dictionary elements");
is([keys %{$data->[1]->{hash}}], [qw(array hash)], "can get keys of a Dictionary");
