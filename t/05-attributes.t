use v6.d;
use Trait::Traced;
use Tracer::Default;
use Test;

sub trace(&trace, &parse?) {
    my Str:D $filename = 'Trait-Traced-testing-' ~ 1_000_000.rand.floor ~ '.txt';
    my $*TRACER := Tracer::Default[$*TMPDIR.child($filename).open: :w];
    LEAVE {
        $*TRACER.handle.close;
        $*TRACER.handle.path.unlink;
    }
    trace;
    $*TRACER.handle.flush;
    parse $*TRACER.handle.path.slurp(:close) with &parse;
}

plan 14;

trace {
    lives-ok {
        my class WithTracedScalar {
            has $!traced is traced;
            method set-traced($!traced) { }
        }.new.set-traced: 'ok';
    }, 'can assign to traced ro attributes...';
}, -> Str:D $output {
    ok $output, '...which produce output...';
    ok $output ~~ / <after '<== '> '$!traced' /,
      '...that claims the attribute has the correct symbol...';
    ok $output ~~ / <after '==> '> '"ok"' /,
      '...and has the correct result';
};

trace {
    lives-ok {
        my class WithTracedScalar {
            has $.traced is rw is traced;
        }.new.traced = 'ok';
    }, 'can assign to traced rw attributes...';
}, -> Str:D $output {
    ok $output, '...which produces output...';
    ok $output ~~ / <after '==> '> '"ok"' /,
      '...that has the correct result';
};

trace {
    lives-ok {
        my class WithTracedPositional {
            has @!traced is traced;
            method set-traced(+@!traced) { }
        }.new.set-traced: 1, 2, 3;
    }, 'can STORE in traced ro attributes...';
}, -> Str:D $output {
    ok $output, '...which produce output...';
    ok $output ~~ / <after '<== '> '@!traced' /,
      '...that claims the attribute has the correct symbol...';
    ok $output ~~ / <after '==> '> '[1, 2, 3]' /,
      '...and has the correct result';
};

trace {
    lives-ok {
        my class WithTracedPositional {
            has @.traced is rw is traced;
        }.new.traced = 1, 2, 3;
    }, 'can STORE in traced rw attributes...';
}, -> Str:D $output {
    ok $output, '...which produces output...';
    ok $output ~~ / <after '==> '> '[1, 2, 3]' /,
      '...that has the correct result';
};

# vim: ft=perl6 sw=4 ts=4 sts=4 et