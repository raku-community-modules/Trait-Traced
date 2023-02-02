![Build Status](https://github.com/Kaiepi/ra-Trait-Traced/actions/workflows/test.yml/badge.svg)

NAME
====

Trait::Traced - Automagic tracing

SYNOPSIS
========

```perl6
use Trait::Traced;

# Oops! After some late night programming, we ended up with a buggy Power class,
# but we're having trouble finding the bug! No big deal; just slap an
# `is traced` on the class...
class Power is traced {
    has Numeric:D $.base     is required;
    has Numeric:D $.exponent is required;

    method new(::?CLASS:_: Numeric:D $base, Numeric:D $exponent --> ::?CLASS:D) {
        self.bless: :$base, :$exponent
    }

    multi method Numeric(::?CLASS:D: --> Numeric:D) {
        $!exponent ** $!base
    }
}

# ...and it will automatically get traced! With the output this generates, it's
# clear the bug's in the Numeric method:
my Power:D $two-cubed .= new: 2, 3;
quietly +$two-cubed; # OUTPUT:
#         2 ATTRIBUTE ASSIGN [1 @ 1612442348.394997]
#     <== has Numeric:D $.base (Power)
#     ==> 2
#         3 ATTRIBUTE ASSIGN [1 @ 1612442348.400778]
#     <== has Numeric:D $.exponent (Power)
#     ==> 3
#     1 ROUTINE CALL [1 @ 1612442348.393752]
# <== method new (Power)
#     self:      (Power)
#     $base:     2
#     $exponent: 3
#     *%_:       {}
# ==> Power.new(base => 2, exponent => 3)
#     4 ROUTINE CALL [1 @ 1612442348.417632]
# <== multi method Numeric (Power)
#     self: Power.new(base => 2, exponent => 3)
#     *%_:  {}
# ==> 9
```

DESCRIPTION
===========

Trait::Traced is a library that provides the `is traced` trait, which allows anything a trait can be applied to to be traced. This is designed in such a way as to allow anyone to add custom tracing support of their own to this trait without needing to modify the library itself.

Documentation for its various features may be found at its [wiki](https://github.com/raku-community-modules/Trait-Traced/wiki).

AUTHOR
======

Ben Davies (Kaiepi)

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Ben Davies

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

