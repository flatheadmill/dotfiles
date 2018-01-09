[![Build Status](https://travis-ci.org/bigeasy/interrupt.svg)](https://travis-ci.org/bigeasy/interrupt) [![Coverage Status](https://coveralls.io/repos/bigeasy/interrupt/badge.svg?branch=master&service=github)](https://coveralls.io/github/bigeasy/interrupt?branch=master)

*TODO*: Refactor this diatribe. I don't care about type anymore. JavaScript and
espeically Node.js is not so terribly mysterious that you cannot guess what will
be thrown. Adding an `interrupt` property would be enough, I believe, to make
sure you catch this exception by type.

First, this is about Node.js.

Let me tell you about this assuming Node.js. When you throw a message, you want
everything you'd hope the user would tell you about the error in the `stack`.
The `stack` will get dumped to standard out by the default exception handler.
This is what is most likely to come your way in a GitHub issue. It is what is
mostly likely to be written to a log message.

And then...

It's advantage is the lengths it will go to to preserve context and make a
meaningful stack message. I've found that the context I desire for these
exceptions must be captured when thrown. The message you'd want to see in a log
message, the message you want to see in a user's bug report must be formatted
and ready to go. It must be the likely message. You can't put the necessary
information in the exception so that a message might be formatted if the user so
chooses. You want to smash as much information in `stack` so that the likely
outcome is.

Then maybe it is about Browserify.

This will work in the browser, but it does depend upon `util.inspect`.

Errors that you can catch by type.

Interrupt is part of the [Cadence](https://github.com/bigeasy/cadence) Universe.
Cadence provides a robust asynchronous try/catch mechansism. Thus, I use
try/catch error handling in all my evented Node.js programs.

When you throw an exception in any other language, you're able to catch those
exceptions by type, so that you only handle the exceptions you know how to
handle.

You can't catch exceptions by type in JavaScript. The best you can do is check
the error message. There is no real way to indicate an exception type that was
thrown deep within your code.

With Interrupt you can add namepsaces to your exceptions and catch specific
exceptions based on namespace and by matching the message.

### Synopsis

```javascript
var assert = require('assert')
var interrupt = require('interrupt').createIterruptor('bigeasy.example')

try {
    throw interrupt(new Error('convert'), { value: 1 })
}  catch (error) {
    interrupt.rescue('bigeasy.example.convert', function () {
        assert.equal(error.value, 1)
    })(error)
}
```

In the above example we create an `interrupt` instance to use in our module
providing a namespace that will be used to distinquish our errors. The naming
convention for interrupt is your GitHub name and the name of the project.

We create a new exception by calling `interrupt`, passing a `new Error` with a
message that is used to distinguish the error. You can also provide a map of
properties that will be added to the error for context.

In the catch block we call `interrupt.rescue()` with a pattern to match the
specific exception. The pattern will match the combination of the `interrupt`
namespace and exception message. If the pattern matches, then the exception is
caught. If it does not match, the exception is rethrown.

### Unambiguous Exceptions

What if you want to catch an exception from a third party library. You use a
try/catch block to choke up on the point of failure and wrap the result in an
interupt.

```javascript
var assert = require('assert')
var interrupt = require('interrupt').createIterruptor('bigeasy.example')

try {
    try {
        library.frobinate(1)
    } catch (error) {
        // almost certainly a frobination exception.
        throw interrupt(new Error('frobinate'), { cause: error })
    }
    library.doManyOtherThings()
} catch (error) {
    interrupt.rescue('bigeasy.example.frobinate', function (error) {
        console.log('frobination failure')
        console.log(error.cause.stack)
    })(error)
}
```

In the above example we've put a catch block around the operation we know might
fail, that we know how to recover from, but rather than try and guess the error
in some remove catch block when it has unwound the stack, we immediately wrap it
in using `interrupt`. The `rescue` function will only catch Interrupt
exceptions, it will rethrow all others.

In my programs, I find that the two patterns above make try catch useful again.

### Selecting Exceptions

```javascript
var assert = require('assert')
var interrupt = require('interrupt').createIterruptor('bigeasy.example')

try {
    if (!library.frobinate(1)) {
        throw interrupt(new Error('forbinate', { frobination: 1 })
    }
    if (!library.reticulate()) {
        throw interrupt(new Error('reticuate'))
    }
} catch (error) {
    interrupt.rescue([
        'bigeasy.example.frobinate', function (error) {
            console.log('frobination failure: ' + error.frobination)
        },
        'bigeasy.example.reticulate', function () {
            console.log('reticuation failure')
        },
        'bigeasy.example', function () {
            console.log('other library failure')
        }
    ])(error)
}
```

### With Cadence

When combine with Cadence, I have robuts asynchronous try/catch with unambiguous
error handling.

```javascript
function Service (processor) {
    this._processor = processor
}

Service.prototype.serve = cadence(function (async, file) {
    async([function () {
        async([function () {
            fs.readFile(file, 'utf8', async())
        }, function (error) {
            throw interrupt(new Error('readFile'), { cause: error, file: file })
        }], function (file) {
            this._processor.process(file, async())
        })
    }, function (error) {
        interrupt.rescue('bigeasy.serivce.readFile', function (error) {
            console.log('cannot read file: ' + error.file)
        })(error)
    }])
})
```

The above example shows how we can catch an error locally, then wrap it so that
we know to catch it in the outer most rescue loop. In this example, it would be
better to log and return, but imagine if you will a much more complicated
example where the file read is nested deeply in the call stack.
