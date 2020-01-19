use v6.d;
#|[ A role done by classes that handle tracing for a type of event. ]
unit role Traced;

my atomicint $id = 0;
#|[ The ID of the trace. ]
has Int:D     $.id        = ++⚛$id;
#|[ The ID of the thread the trace was taken in. ]
has Int:D     $.thread-id is required;
#|[ The instant the trace was taken at. ]
has Instant:D $.timestamp is required;

#|[ Wraps an object of this trace's event type to make it traceable somehow. ]
proto method wrap(::?CLASS:U: | --> Mu) {*}

#|[ Traces an event. ]
method trace(::?CLASS:U: :$thread-id = $*THREAD.id, |args --> Bool:D) {
    my ::?CLASS:D $trace .= new: :$thread-id, |args;
    my Str:D      $method = $*TRACER.t ?? 'say' !! 'put';
    $*TRACER."$method"($trace)
}

#|[ The colour to use for the key of the trace's output. ]
method colour(::?CLASS:_: --> Int:D) { ... }
#|[ The key of the trace's output. ]
method key(::?CLASS:_: --> Str:D)    { ... }

#|[ Whether or not the event traced succeeded. ]
method success(::?CLASS:D: --> Bool:D) { ... }

#|[ The title of the trace. ]
method title(::?CLASS:D: Bool:D :$colour! --> Str:D) {
    sprintf "%d [%d @ %f]", $!id, $!thread-id, $!timestamp.Rat
}

#|[ Produces the header of the trace's output. ]
proto method header(::?CLASS:D: Bool:D :$colour! --> Str:D) {
    $colour
        ?? sprintf("<== \e[%s;1m[%s]\e[0m \e[1m%s\e[0m", $.colour, $.key, {*})
        !! sprintf("<== [%s] %s", $.key, {*})
}

#|[ Produces the entries of the trace's output, if any. ]
proto method entries(::?CLASS:D: Bool:D :$colour! --> Seq:D) {
    my Pair:D @entries = {*} ==> map({
        state Str:D $format  = $colour ?? "\e[1m%s\e[0m:%s %s" !! "%s:%s %s";
        state Int:D $width   = @entries.map(*.key.chars).max;
        my    Str:D $padding = ' ' x $width - .key.chars;
        sprintf $format, .key, $padding, .value
    })
}
multi method entries(::?CLASS:D: --> Seq:D) { ().Seq }

#|[ Produces the footer of the trace's output. ]
proto method footer(::?CLASS:D: Bool:D :$colour! --> Str:D) {
    my Str:D $prefix = $.success ?? '==>' !! '!!!';
    $colour
        ?? sprintf("%s \e[1m%s\e[0m", $prefix, {*})
        !! sprintf("%s %s", $prefix, {*})
}

multi method lines(::?CLASS:D: Bool:D :$colour = False --> Seq:D) {
    gather {
        take $.title: :$colour;
        take $.header: :$colour;
        take ' ' x 4 ~ $_ for @.entries: :$colour;
        take $.footer: :$colour;
    }
}

BEGIN my $THREAD-INDENT-LEVELS = %();
#|[ Bumps the indentation level of a trace while executing the given block. ]
method !protect(::?CLASS:_: &block is raw --> Mu) is raw {
    cas $THREAD-INDENT-LEVELS, &increment-indent-level;
    LEAVE cas $THREAD-INDENT-LEVELS, &decrement-indent-level;
    block
}
sub increment-indent-level(%indent) {
    my Int:D $id = $*THREAD.id;
    if %indent{$id}:exists {
        %indent{$id}++;
    } else {
        %indent{$id} = 0;
    }
    %indent
}
sub decrement-indent-level(%indent) {
    my Int:D $id = $*THREAD.id;
    if %indent{$id}:exists {
        %indent{$id}--;
    } else {
        %indent{$id} = 0;
    }
    %indent
}

multi method Str(::?CLASS:D: --> Str:D) {
    @.lines
==> map(&INDENT)
==> join($?NL)
}
multi method gist(::?CLASS:D: --> Str:D) {
    @.lines(:colour)
==> map(&INDENT)
==> join($?NL)
}
sub INDENT(Str:D $line --> Str:D) {
    my Int:D $level = (⚛$THREAD-INDENT-LEVELS){$*THREAD.id};
    ' ' x 4 * $level ~ $line
}
