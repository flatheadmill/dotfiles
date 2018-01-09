var loop = 'var i = 0\n\
while (i < 10) {\n\
    i++ // foo\n\
    console.log(i)\n\
}'

var f = 'function () {\n\
    var i = 0\n\
    while (i < 10) {\n\
        i++ // foo\n\
        console.log(i)\n\
    }\n\
    console.log(i)\n\
}'

var blank = 'function () {\n\
    var i = 0\n\
    while (i < 10) {\n\
        i++ // foo\n\
        console.log(i)\n\
    }\n\
\n\
    console.log(i)\n\
}'

require('proof')(5, prove)

function prove (assert) {
    var s  = require('../..'), inner
    assert(inner = s('                  \n\
        var i = 0                       \n\
        while (i < 10) {                \n\
            ', '', '                    \n\
            ', 'i++', ' // foo          \n\
            console.log(i)              \n\
        }                               \n\
    '), loop, 'indented')
    assert(s(['                         \n\
        function () {                   \n\
            ', inner, '                 \n\
                                        \n\
            console.log(i)              \n\
            // __reference__            \n\
        }                               \n\
    ']), f, 'nested multi-line')
    assert(s(['                         \n\
        function () {                   \n\
            ', inner, '                 \n\
            // __blank__                \n\
            console.log(i)              \n\
        }                               \n\
    ']), blank, 'nested blank line')
    assert(s('                          \n\
        var i = 0                       \n\
        while (i < 10) {                \n\
            i++ // foo                  \n\
            console.log(i)              \n\
        ', '}', '                       \n\
    '), loop, 'dedented')
    assert(s('                          \n\
        var i = 0                       \n\
        ', 'while (i < 10)', ' {        \n\
            i++ // foo                  \n\
            console.log(i)              \n\
        }                               \n\
    '), loop, 'unchanged')
}
