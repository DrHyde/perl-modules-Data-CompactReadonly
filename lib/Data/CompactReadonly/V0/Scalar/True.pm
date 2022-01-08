package Data::CompactReadonly::V0::Scalar::True;
our $VERSION = '0.0.6';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Scalar::HeaderOnly';

sub _init { return 1 == 1; }

1;
