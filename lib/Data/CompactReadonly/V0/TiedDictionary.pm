package Data::CompactReadonly::V0::TiedDictionary;

use strict;
use warnings;

sub TIEHASH{
    my($class, $object) = @_;
    return bless({ object => $object }, $class);
}

sub EXISTS { shift()->{object}->exists(shift()); }
sub FETCH  { shift()->{object}->element(shift()); }
sub SCALAR { shift()->{object}->count(); }

sub FIRSTKEY {
    my $tiedhash = shift();
    $tiedhash->{nextkey} = 1;
    $tiedhash->{object}->_nth_key(0);
}

sub NEXTKEY {
    my $tiedhash = shift();
    return undef if($tiedhash->{nextkey} == $tiedhash->{object}->count());
    $tiedhash->{object}->_nth_key($tiedhash->{nextkey}++);
}

sub STORE { die("Illegal access: store: this is a read-only database\n"); }
sub DELETE { shift()->STORE() }
sub CLEAR  { shift()->STORE() }

1;