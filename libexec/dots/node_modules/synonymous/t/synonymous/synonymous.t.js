var usage = '\
usage: synonymous <options> file1 file2\n\
\n\
options:\n\
    --foo'

require('proof')(17, prove)

/*

    ___ usage, sub ___ en_US ___
    usage: synonymous <options> file1 file2

    options:
        --foo
    ___ usage, sub, $ ___ en_US ___

        multi line:
          One line.

          And then another.
        immediate:
          No space before or after.
        following: Message follows label.

        main message:
          This is the main message: %s => %d.

        delimiteresque:
          ___ usage, sub, $ ___ en_US ___

        named parameters(key, value):
          Here are some named parameters: %s => %d && %d.

        plural(number, number):
          There are %d %(number/numbers).

    ___ usage, "string with \"" ___ en_US ___
    x
    ___ usage ___ en_GB ___
    usage: synonymous <options> file1 file2

    options:
        --foo
    ___ . ___

*/

function prove (assert) {
    var Dictionary = require('../..')
    var fs = require('fs')
    var source = fs.readFileSync(__filename, 'utf8')
    var dictionary = new Dictionary
    dictionary.load(source)
    assert(dictionary.getText('en_US', [ 'usage', 'sub' ]), usage, 'text')
    assert(dictionary.getText('en_US', [ 'usage', 'string with "' ]), 'x', 'double quoted text')
    assert(dictionary.getText('en_US', [ 'usage', 'foo' ]), null, 'text not found')
    assert(dictionary.getString('en_US', [ 'usage', 'sub' ], 'main message'), {
        text: 'This is the main message: %s => %d.', order: [ '1' ]
    }, 'string found')
    assert(dictionary.getString('en_US', [ 'usage', 'foo' ], 'main message'), null, 'string path not found')
    assert(dictionary.getString('en_US', [ 'usage', 'sub' ], 'x'), null, 'string not found')
    assert(dictionary.getString('en_US', [ 'usage', 'sub' ], 'delimiteresque'),
          { text: '___ usage, sub, $ ___ en_US ___', order: [ 1 ] },
          'ignore delimiter if indented')
    assert(dictionary.getString('en_US', [ 'usage', 'sub' ], 'named parameters'), {
        text: 'Here are some named parameters: %s => %d && %d.',
        order: [ 'key', 'value' ]
    }, 'string not found')
    assert(dictionary.format('en_US', [ 'usage', 'sub' ], 'named parameters', {
        key: 'a', value: 1, fred: 2
    }), 'Here are some named parameters: a => 1 && 2.', 'format')
    assert(dictionary.format('en_US', [ 'usage', 'sub' ], 'main message', [
        'a', 1
    ]), 'This is the main message: a => 1.', 'format')
    assert(dictionary.format('en_US', [ 'usage', 'sub' ], 'main message', 'a', 1),
        'This is the main message: a => 1.', 'format')
    assert(dictionary.format('en_US', [ 'usage', 'sub' ], 'missing message', []), null, 'missing message')
    assert(dictionary.getString('fr_FR', [ 'usage', 'sub' ], 'x'), null, 'language not found')
    assert(dictionary.getText('en_GB', [ 'usage' ]), usage, 'last entry')
    assert(dictionary.getKeys('en_US', []), [ 'usage' ], 'root keys')
    assert(dictionary.getKeys('en_US', [ 'usage' ]), [ 'sub', 'string with "' ], 'keys')
    assert(dictionary.getLanguages(), [ 'en_US', 'en_GB' ], 'get languages')
}
