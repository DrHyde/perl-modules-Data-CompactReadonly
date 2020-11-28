package Data::CROD::V0::NegativeScalar;

use warnings;
use strict;
use base 'Data::CROD::V0::Scalar';

sub _init {
    my($class, %args) = @_;
    return -1 * $class->SUPER::_init(%args);
}

1;
