var sprintf = require('sprintf')
var slice = [].slice
var assert = require('assert')

var STRING = /^(\s*)([^:(]+)(?:\((\d+(?:\s*,\s*\d+)*)\)|\((\w[\w\d]*(?:\s*,\s*\w[\w\d]*)*)\))?:\s*(.*)$/
var DELIMITER = /^(?:(\s*)___\s+((?:\d+|\w[\w\d]+|\$)(?:\s*,\s*(?:\d+|[\w\d]+|"(?:[^"\\]*(?:\\.[^"\\]*)*)"|\$))*)\s+___\s+((?:[a-z]{2}_[A-Z]{2})(?:\s*,\s*[a-z]{2}_[A-Z]{2})*)\s+___\s*|(\s*)___\s+\.\s+___\s*)$/
var PARAMETER = /^(?:(\w[\w\d]+|\$)|("(?:[^"\\]*(?:\\.[^"\\]*)*)"))\s*(?:,\s*(.*))?$/

// Extract message strings from the strings section of a usage message.
function strings (strings, lines) {
    var i, I, j, J, $, spaces, key, order, line, message = [], dedent = Number.MAX_VALUE

    OUTER: for (i = 0, I = lines.length; i < I; i++) {
        if (($ = STRING.exec(lines[i]))) {
            spaces = $[1].length, key = $[2].trim(), order = $[3] || $[4] || '1', line = $[5], message = []
            if (line.length) message.push(line)
            for (i++; i < I; i++) {
                if (/\S/.test(lines[i])) {
                    $ = /^(\s*)(.*)$/.exec(lines[i])
                    if ($[1].length <= spaces) break
                    dedent = Math.min($[1].length, dedent)
                }
                message.push(lines[i])
            }
            for (j = line.length ? 1 : 0, J = message.length; j < J; j++) {
                message[j] = message[j].substring(dedent)
            }
            if (message[message.length - 1] == '') message.pop()
            strings[key] = { text: message.join('\n'), order: order.split(/\s*,\s*/) }
            i--
        }
    }

    return strings
}

function Dictionary () {
    this._languages = { order: [], branch: {} }
}

Dictionary.prototype.load = function (source) {
    var $
    var lines = source.split(/\r?\n/)
    var areStrings
    var text
    for (var i = 0, I = lines.length; i < I; i++) {
        if ($ = DELIMITER.exec(lines[i])) {
            var spaces = $[1] == null ? $[4] : $[1], terminator = $[4] != null
            if (text) {
                if (spaces.length > indent) {
                    text.push(lines[i].substring(indent))
                    continue
                }
                languages.forEach(function (language) {
                    if (this._languages.order.indexOf(language) == -1) {
                        this._languages.order.push(language)
                    }
                    var branch = this._getBranch(language, vargs, true)
                    if (areStrings) {
                        strings(branch.strings, text)
                    } else {
                        branch.body = text.join('\n')
                    }
                }, this)
                indent = -1
                text = null
            }
            if (terminator) {
                continue
            }
            var vargs = [], indent = $[1].length,
                parameters = $[2], languages = $[3]
            while (parameters.length) {
                $ = PARAMETER.exec(parameters)
                vargs.push($[1] ? $[1] : JSON.parse($[2]))
                parameters = $[3] || ''
            }
            if (areStrings = vargs[vargs.length - 1] == '$') {
                vargs.pop()
            }
            assert(vargs.every(function (arg) { return arg != '$' }), 'invalid argument')
            languages = languages.split(/\s*,\s*/)
            text = []
        } else if (text) {
            text.push(lines[i].substring(indent))
        }
    }
}

Dictionary.prototype.getLanguages = function () {
    return this._languages.order.slice()
}

Dictionary.prototype._getBranch = function (language, path, create) {
    var branch = this._languages.branch[language], child
    if (!branch) {
        if (create) {
            branch = this._languages.branch[language] = {
                branches: {},
                name: language,
                strings: {}
            }
        } else {
            return { body: null, strings: {} }
        }
    }
    for (var i = 0, I = path.length; i < I; i++) {
        child = branch.branches[path[i]]
        if (!child) {
            if (create) {
                child = branch.branches[path[i]] = {
                    name: path[i],
                    branches: {},
                    body: null,
                    strings: {}
                }
            } else {
                return { body: null, strings: {} }
            }
        }
        branch = child
    }
    return branch
}

Dictionary.prototype.getText = function (language, path) {
    return this._getBranch(language, path).body
}

Dictionary.prototype.getString = function (language, path, key) {
    return this._getBranch(language, path).strings[key] || null
}

Dictionary.prototype.getKeys = function (language, path) {
    return Object.keys(this._getBranch(language, path).branches)
}

Dictionary.prototype.format = function (language, path, key) {
    var vargs = slice.call(arguments, 3), args, keys
    var string = this.getString(language, path, key)
    if (!string) {
        return null
    }
    if (typeof vargs[0] === 'object') {
        vargs = vargs[0]
    }
    if (Array.isArray(vargs)) {
        args = vargs.map(function (_, index) {
            var order = string.order[index] || ''
            return vargs[/^\d+$/.test(order) ? order - 1 : index]
        })
    } else {
        keys = Object.keys(vargs)
        args = keys.map(function (_, index) {
            var order = string.order[index]
            return vargs[order ? order : keys[index]]
        })
    }
    return sprintf.apply(null, [ string.text].concat(args))
}

module.exports = Dictionary
