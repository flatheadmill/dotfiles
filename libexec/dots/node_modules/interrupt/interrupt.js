var util = require('util')
var slice = [].slice

exports.createInterrupter = require('./bootstrap').createInterrupterCreator(Error)
