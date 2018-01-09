# Programmatic Diary

```javascript
function (foo, fields, baz) {
    foo.forEach(function (item) {
        if ($.test(item.type == 'integer')) {
            _$field = (_$field & $sign) ? ($mask - _$field + 1) * -1 : _$field
        } else {
        }
    })

    $(fields = fields.forEach(function () {
    }))

    $.switch(index, function () {
        return $.forEach(function (racket) {
            return
        })
    })

    while (bite != $stop) {
        if (start == end) return start
        _$field += Math.pow(256, bite) * buffer[start++]
        $($direction < 0, bite--, bite++)
    }

}

function other ($) {
    var $, bits = (mask >>> (field.bits - pack.bits)).toString(16)
    unsigned = $reference
    unsigned = unsigned < 0 ? bits + unsigned + 1 : unsigned
}
```

Now that I think about it, why am I trying to survive minification? The route
I'm taking now would require the user to install a parser. That's more
complicated than minification isn't it?

## Concerns and Decisions

 * Decided that I do not care about minification. Realized, too, that a
 generated generator that contains an AST would be minification safe.

## Generator Output

Generators can be output, written to file, then distributed as source. They can
also be unit tested.

## Literals Versus Identifiers

To get going with Programmatic we're going to need build a project, and that
project is Packet. When I created this library as a string manipulation library,
I distinquished between replacing literals and identifiers. Whatever reasoning I
used then, I'm going to use now. After having a code base, I'll be able to see
if the distinction can be removed.

Also, I'm not going to beat too hard on the syntax. I'll probably use some sort
of dot notation on the initial variable, the `$` variable, for now. After Packet
is complete, I can look and see if there are patterns that would make more
sense.

```javascript
$('_' + value) // means evaluate
($ + value) // could mean literal, or quote.
$ + value // could also mean.
$(function () {
    return calculated.values
}) // evaluated at runtime.
```

## Multi-Line Strings

Key to making Programmatic work for you is having an editor that correctly
highlghts multi-line strings. My didn't, and so I've included a patch the the
JavaScript syntax file for Vim.
