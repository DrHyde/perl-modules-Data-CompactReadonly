use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;
use Test::Exception;
use Test::Differences;

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
open(my $fh, '<:unix', $filename) || die("Can't read $filename: $!\n");
my $tied= Data::CROD->read($fh, 'tie' => 1);

open(my $fh2, '<:unix', $filename) || die("Can't read $filename: $!\n");
my $untied= Data::CROD->read($fh2);

is($#{$tied}, $untied->count() - 1, "can de-ref and count elements in an Array");
is($tied->[2], 'fishfingers', "can de-ref and retrieve an array element");
is($#{$tied->[0]}, $untied->element(0)->count() - 1, "those work on nested arrays");
throws_ok { $tied->[3] } qr/Invalid element: 3: out of range/, "can't fetch illegal array index";
throws_ok { $tied->[1] = 3 } qr/Illegal access: store: this is a read-only database/, "can't write to an array";
ok(exists($tied->[0]), "exists() works on an existent index");
ok(!exists($tied->[10]), "... and on a non-existent index");

throws_ok { $tied->[1]->{cow} } qr/Invalid element: cow: doesn't exist/, "can't fetch illegal dict key";
throws_ok { $tied->[1]->{hash} = 'pipe' } qr/Illegal access: store: this is a read-only database/, "can't write to a hash";
is($tied->[1]->{hash}->{lemon}, 'curry', "can de-ref and retrieve Dictionary elements");
ok(exists($tied->[1]->{hash}->{lemon}), "exists() works on an existent key");
ok(!exists($tied->[1]->{hash}->{lime}), "... and on a non-existent key");
eq_or_diff([keys %{$tied->[1]}], [qw(array hash)], "can get keys of a Dictionary");
is(scalar(%{$tied->[1]}), 2, "can count keys in the hash");

eq_or_diff(
    [@{$tied->[0]}],
    [5, 4, 3, 2, 1, 0],
    "can de-ref an array completely"
);
eq_or_diff(
    { %{$tied->[1]} },
    { hash => { lemon => 'curry' }, array => [qw(lemon curry)] },
    "can de-ref a dictionary completely"
);

done_testing;
