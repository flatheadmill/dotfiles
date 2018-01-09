var slice = [].slice
var util = require('util')

exports.createInterrupterCreator = function (_Error) {
    return function (path) {
        function vargs (vargs, callee) {
            var name = vargs.shift(), cause, context, options
            if (vargs[0] instanceof Error) {
                cause = vargs.shift()
            } else {
                cause = null
            }
            context = vargs.shift() || {}
            options = vargs.shift() || {}
            if (cause != null) {
                options.cause = cause
            }
            return {
                name: name,
                context: context,
                options: options,
                callee: options.callee || callee
            }
        }
        function ejector (name, cause, context, options) {
            return eject(vargs(slice.call(arguments), ejector))
        }
        function eject (args) {
            var properties = args.options.properties || {}
            var keys = Object.keys(args.context).length
            var body = ''
            var dump = ''
            var stack = ''
            var qualifier = path + '#' + args.name
            if (keys != 0 || args.options.cause) {
                body = '\n'
                if (keys != 0) {
                    dump = '\n' + util.inspect(args.context, { depth: args.options.depth || Infinity }) + '\n'
                }
                if (args.options.cause instanceof Error) {
                    dump += '\ncause: ' + args.options.cause.stack + '\n\nstack: ' + qualifier
                }
            }
            var message = qualifier + body + dump
            var error = new Error(message)
            for (var key in args.context) {
                error[key] = args.context[key]
            }
            for (var key in args.options.properties) {
                error[key] = args.options.properties[key]
            }
            if (args.options.cause) {
                error.cause = args.options.cause
            }
            error.interrupt = path + '#' + args.name
            if (_Error.captureStackTrace) {
                _Error.captureStackTrace(error, args.callee)
            }
            return error
        }
        ejector.assert = function (condition) {
            if (!condition) {
                throw eject(vargs(slice.call(arguments, 1), ejector.assert))
            }
        }
        return ejector
    }
}
