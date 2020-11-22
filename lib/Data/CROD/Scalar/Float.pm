package Data::CROD::Scalar::Float;

use warnings;
use strict;
use base 'Data::CROD::Scalar::Huge';

# FIXME this uses pack()'s d format underneath, which exposes the
# native machine floating point format. This is not guaranteed to
# actually be IEEE754. Yuck. Need to find a comprehensible spec and
# a comprehensive text suite and implement my own.
use Data::IEEE754 qw(unpack_double_be);

sub _decode_word {
    my($class, $word) = @_;
    return unpack_double_be($word);
}

1;
