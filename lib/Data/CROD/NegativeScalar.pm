package Data::CROD::NegativeScalar;

use warnings;
use strict;
use base 'Data::CROD::Scalar';

sub _init {
    my($class, %args) = @_;
    return -1 * $class->SUPER::_init(%args);
}

1;
