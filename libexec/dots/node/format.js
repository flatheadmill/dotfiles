#!/usr/bin/env node

var $ = require('programmatic')

var pwd = process.cwd(), path = require('path')
var json = require(path.join(pwd, 'package.json'))

;[ 'dependencies', 'devDependencies' ].forEach(function (property) {
    for (var module in json[property]) {
        var loaded = require(path.join(pwd, 'node_modules', module, 'package.json'))
        if (/\.x$/.test(json[property][module])) {
            json[property][module] = loaded.version.replace(/\.\d+$/, '.x')
        }
    }
})

for (var key in json) {
    var value = json[key]
    switch (typeof value) {
    case 'object':
        if (Array.isArray(value) && value.length == 0) {
            json[key] = '[]'
        }
        break
    case 'number':
    case 'boolean':
    case 'string':
        json[key] = JSON.stringify(value)
        break
    }
}

var fields = ([
        'private', 'name', 'version', 'description', 'keywords', 'author',
        'contributors', 'homepage', 'bugs', 'license', 'repository',
        'dependencies', 'devDependencies', 'main', 'bin', 'scripts', 'nyc'
    ])
    .filter(function (key) {
        return json[key]
    })
    .map(function (key) {
        if (key == 'description') {
            return $('\n\
                "description":                                                          \n\
                // __blank__                                                          \n\
                //' + json[key] + ',                                                    \n\
                // __blank__                                                          \n\
            ')
        } else if (typeof json[key] == 'string') {
            var name = JSON.stringify(key) + ':'
            var spaces = new Array(25 - name.length).join(' ')
            return name + spaces + json[key] + ','
        } else if (Array.isArray(json[key])) {
            if (typeof json[key][0] == 'string') {
                var lengths = []
                var array = json[key].map(function (value, index) {
                    value = JSON.stringify(value)
                    lengths[index] = value.length
                    return value
                })
                var lines = [], line = [], length = 0
                for (var i = 0, I = array.length; i < I; i++) {
                    if (length > 44) {
                        length = 0
                        lines.push(line.join(', '))
                        line = []
                    }
                    line.push(array[i])
                    length += lengths[i] + 2
                }
                lines.push(line.join(', '))
                lines = lines.map(function (line) {
                    return '//                  ' + line
                })
                return $('\n\
                    ' + JSON.stringify(key) + ':                                        \n\
                    [                                                                   \n\
                        // __reference__ \n\
                        ', lines.join(',\n'), '                               \n\
                    ],                                                                  \n\
                ')
                    
            } else {
                var contributors = json[key].map(function (contributor) {
                    var fields = []
                    for (var key in contributor) {
                    var name = JSON.stringify(key)
                    var spaces = new Array(9 - name.length).join(' ')
                        fields.push('//                  ' +
                            JSON.stringify(key) + ':' + spaces + JSON.stringify(contributor[key]))
                    }
                    return $('                                                          \n\
                    // __reference__                                                \n\
                        ', fields.join(',\n'), '                                        \n\
                    ')
                }).join('\n},\n{\n')
                return $('                                                              \n\
                    ' + JSON.stringify(key) + ':                                       \n\
                    [{                                                                  \n\
                    ', contributors, '                                                  \n\
                    }],                                                                 \n\
                ')
            }
        } else {
            var properties = Object.keys(json[key])
            if (key == 'nyc') {
            return $('\n\
                ' + JSON.stringify(key) + ':                                        \n\
                {                                                                   \n\
                    ', "//                  [ " + json[key].exclude.map(function (pattern) {
                        return JSON.stringify(pattern)
                    }).join(', '), ' ] \n\
                    // __reference__ \n\
                },                                                                  \n\
            ')
            }
            if (key == 'dependencies' || key == 'devDependencies' || key == 'bin') {
                properties.sort()
            }
            properties = properties.map(function (property) {
                var value = json[key][property]
                property = JSON.stringify(property)
                if (key == 'dependencies' || key == 'devDependencies' || key == 'bin') {
                    var spaces = new Array(32 - property.length).join(' ')
                } else {
                    var spaces = ' '
                }
                return property + ':' + spaces + JSON.stringify(value)
            })

            properties = properties.map(function (line) {
                return '//                  ' + line
            }).join(',\n')

            return $('\n\
                ' + JSON.stringify(key) + ':                                        \n\
                {                                                                   \n\
                    ', properties, '\n\
                    // __reference__ \n\
                },                                                                  \n\
            ')
        }
    })

fields[fields.length - 1] = fields[fields.length - 1].replace(/,([^,]*$)/, '$1')

var source = $('\
{                                                                                       \n\
    ', fields.join('\n'), ' \n\
}                                                                                       \n\
')

console.log($([source]).replace(/^(\s+)\/\//gm, '$1  '))

// vim: set tw=0:
