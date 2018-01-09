var interrupt = require('..').createInterrupter('module')

var first = interrupt({ name: 'first' })
var second = interrupt({ name: 'second', cause: first })
var third = interrupt({ name: 'third', cause: second })

console.log(third.stack)
