var __slice = [].slice

function delineate (lines) {
    return lines.split(/\n/).map(function (line) {
        var $ = /^(\s*)(.*)$/.exec(line)
        return [ $[1].length, $[2].trim() ]
    })
}

function space (count) {
    return new Array(count + 1).join(' ')
}

module.exports = function () {
    var parent = -1, spaces = -1, source = [], indent = 0, stashed = { spaces: -1, indent: 0 },
        vargs = __slice.call(arguments), tidy
    if (vargs.length == 1 && Array.isArray(vargs[0])) {
        vargs = vargs.shift()
        tidy = true
    }
    vargs.forEach(function (varg, outer) {
        if (parent == -1) {
            spaces = stashed.spaces
            indent = stashed.indent
        } else if (spaces != -1) {
            if (parent > spaces) {
                indent++
            } else if (parent < spaces) {
                indent--
            }
            stashed = { spaces: parent, indent: indent }
            spaces = -1
        }
        delineate(varg).forEach(function (line, inner) {
            if (line[1]) {
                if (!inner && outer && parent == -1) {
                    source[source.length - 1].push(space(line[0]) + line[1])
                } else {
                    if (spaces != -1) {
                        if (line[0] > spaces) {
                            indent++
                        } else if (line[0] < spaces) {
                            indent--
                        }
                    }
                    source.push([ indent, line[1] ])
                    spaces = line[0]
                }
                parent = -1
            } else {
                parent = line[0]
            }
        })
    })
    if (tidy) {
        source = source.filter(function (line) {
            return ! /__reference__/.test(line[1])
        })
    }
    return source.map(function (line) {
        if (tidy && /__blank__/.test(line[1])) {
            return ''
        } else {
            return space(line[0] * 4) + line.slice(1).join('')
        }
    }).join('\n')
}
