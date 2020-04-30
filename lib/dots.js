const assert = require('assert')
const Octokit = require('@octokit/rest')
const fs = require('fs').promises
const path = require('path')
const once = require('prospective/once')
const stream = require('stream')
const children = require('child_process')
const coalesce = require('extant')
const $ = require('programmatic')

class Dots {
    constructor (options) {
        this.arguable = options.arguable
        this.octokit = options.octokit
        this.owner = options.owner
        this.repo = options.repo
        this.dir = options.dir
        this.json = options.json
        this.tmp = options.tmp
    }

    get prefix () {
        if (this.json.dots && this.json.dots.prefix) {
            return `${this.json.dots.prefix}-`
        }
        const $ = /^[^\.]+\.(.*)$/.exec(this.json.name)
        if ($ == null) {
            return ''
        }
        return `${$[1]}-`
    }

    get title () {
        if (this.json.dots && this.json.dots.title) {
            return this.json.dots.title
        }
        const $ = /^([^\.]+)\.(.*)$/.exec(this.json.name)
        const parts = $ == null ? [ this.json.name ] : [ $[1], $[2] ]
        return parts.map(part => part.charAt(0).toUpperCase() + part.substring(1))
                    .join(' ')
    }

    get ownerRepo () {
        return { owner: this.owner, repo: this.repo }
    }

    async issue (issue) {
        const lines = [ `title: ${issue.title}` ]
        if (issue.milestone != null) {
            lines.push(`milestone: ${issue.milestone}`)
        }
        if (issue.project != null) {
            lines.push(`project: ${issue.project}`)
        }
        for (const label of coalesce(issue.labels, [])) {
            lines.push(`label: ${label}`)
        }
        if (issue.body != null && issue.body.length != 0) {
            lines.push('')
            lines.push.apply(lines, issue.body)
        }
        await fs.mkdir(this.tmp, { recursive: true })
        await fs.writeFile(path.resolve(this.tmp, 'issue.txt'), lines.join('\n'), 'utf8')
        let dirty = true, notes = null
        for (;;) {
            const lines = (await this.read(path.resolve(this.tmp, 'issue.txt'))).split('\n') 
            if (lines.filter(line => /\S/.test(line)).length == 0) {
                return null
            }
            for (let i = 0, I = lines.length; i < I; i++) {
                if (!/\S/.test(lines[i])) {
                    break
                }
                const $ = /^([^:]+):\s+(.*)$/.exec(lines[i])
                const name = $[1], value = $[2]
                switch (name) {
                case 'milestone': {
                        const title = (await this.milestone(value)).title
                        if (title != value) {
                            dirty = true
                            lines[i] = `milestone: ${title}`
                        }
                    }
                    break
                case 'project': {
                        const name = (await this.project(value)).name
                        if (name != value) {
                            dirty = true
                            lines[i] = `project: ${name}`
                        }
                    }
                    break
                case 'label': {
                        const name = (await this.labels(value)).name
                        if (name != value) {
                            dirty = true
                            lines[i] = `label: ${name}`
                        }
                    }
                    break
                }
            }
            await fs.writeFile(path.resolve(this.tmp, 'issue.txt'), lines.join('\n'), 'utf8')
            notes = lines.join('\n')
            if (!dirty) {
                break
            }
            await this.zsh('vim $0', path.resolve(this.tmp, 'issue.txt'))
            dirty = false
        }
        return { number: await this.post(), notes }
    }

    async post (amend) {
        const issue = await this.read(path.resolve(this.tmp, 'issue.txt'))
        this.arguable.assert(issue != null, 'issue missing')
        const lines = (await this.read(path.resolve(this.tmp, 'issue.txt'))).split('\n') 
        const posts = [{
            object: 'issues',
            fixup: () => {},
            method: 'create',
            body: { ...this.ownerRepo, labels: [], assignees: [ this.owner ] }
        }]
        for (let i = 0, I = lines.length; i < I; i++) {
            if (!/\S/.test(lines[i])) {
                const body = (i + 1 < lines.length ? lines.slice(i + 1).join('\n') : '').trim()
                if (body != '') {
                    posts[0].body.body = body
                }
                break
            }
            const $ = /^([^:]+):\s+(.*)$/.exec(lines[i])
            const name = $[1], value = $[2]
            switch (name) {
            case 'title': {
                    posts[0].body.title = value
                }
                break
            case 'milestone': {
                    posts[0].body.milestone = (await this.milestone(value)).number
                }
                break
            case 'project': {
                    const { column } = await this.column(value, 'backlog')
                    posts.push({
                        object: 'projects',
                        method: 'createCard',
                        fixup: (posts, post) => post.body.content_id = posts[0].data.id,
                        body: {
                            column_id: column.id,
                            content_type: 'Issue',
                        }
                    })
                }
                break
            case 'label': {
                    posts[0].body.labels.push((await this.labels(value)).name)
                }
                break
            }
        }
        const results = []
        for (const post of posts) {
            post.fixup(posts, post)
            console.log(require('util').inspect(post, { depth: null }))
            const { data } = await this.octokit[post.object][post.method](post.body)
            post.data = data
            results.push(data)
            console.log(post.data)
        }
        await fs.unlink(path.resolve(this.tmp, 'issue.txt'))
        return results[0].number
    }

    async zsh (zsh, ...vargs) {
        vargs.unshift('-c', zsh)
        const child = children.spawn('zsh', vargs, {
            stdio: [ 'inherit', 'inherit', 'inherit', 'pipe' ]
        })
        const output = new stream.PassThrough({ encoding: 'utf8', highWaterMark: Number.MAX_SAFE_INTEGER })
        output.write('x')
        child.stdio[3].pipe(output)
        const closed = once(child.stdio[3], 'close').promise
        const [ code, signal ] = await once(child, 'exit').promise
        await closed
        return { code, signal, output: output.read().substring(1) }
    }

    async read (file) {
        const fs = require('fs').promises
        try {
            return await fs.readFile(file, 'utf8')
        } catch (error) {
            if (error.code != 'ENOENT') {
                throw error
            }
            return null
        }
    }

    json (source) {
        const assert = require('assert')
        if (source == null) {
            return null
        }
        try {
            return JSON.parse(source)
        } catch (error) {
            assert(error instanceof SyntaxError) 
            return source
        }
    }

    exact (string, modifiers) {
        return new RegExp(string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), modifiers)
    }

    async milestone (title) {
        const { data: milestones } = await this.octokit.issues.listMilestonesForRepo({
            owner: this.owner, repo: this.repo
        })
        const regex = this.exact(title, 'i')
        const milestone = milestones.filter(milestone => regex.test(milestone.title)).shift()
        if (milestone == null) {
            this.arguable.abend('cannot find milestone', title)
        }
        return milestone
    }

    async project (name) {
        const { data: projects } = await this.octokit.projects.listForRepo({
            owner: this.owner, repo: this.repo
        })
        const regex = this.exact(name, 'i')
        const project = projects.filter(project => regex.test(project.name)).shift()
        if (project == null) {
            this.arguable.abend('cannot find project', name)
        }
        return project
    }

    async labels (name) {
        const { data: labels } = await this.octokit.issues.listLabelsForRepo({
            owner: this.owner, repo: this.repo
        })
        const regex = this.exact(name, 'i')
        const label = labels.filter(label => regex.test(label.name)).shift()
        if (label == null) {
            this.arguable.abend('cannot find label', name)
        }
        return label
    }

    async column (projectName, columnName) {
        const project = await this.project(projectName)
        const { data: columns } = await this.octokit.projects.listColumns({
            project_id: project.id
        })
        const regex = this.exact(columnName, 'i')
        const column = columns.filter(column => regex.test(column.name)).shift()
        if (column == null) {
            this.arguable.abend('cannot find column', name)
        }
        return { project, column }
    }

    format (json) {
        const format = require('../libexec/dots/node/format')
        return format(JSON.parse(JSON.stringify(json))) + '\n'
    }
}

module.exports = async function (arguable) {
    const dots = JSON.parse(await fs.readFile(path.resolve(process.env.HOME, '.dots')))
    const octokit = new Octokit({ auth: dots.github.token })
    let dir = process.cwd()
    for (;;) {
        const files = await fs.readdir(dir)
        if (~files.indexOf('package.json')) {
            break
        }
        dir = path.resolve(dir, '..')
    }
    const json = JSON.parse(await fs.readFile(path.resolve(dir, 'package.json'), 'utf8'))
    const repository = json.repository
    arguable.assert(repository != null, 'no repository')
    arguable.assert(repository.type == 'git', 'wrong repository type', repository)
    arguable.assert(/^[^\/]+\/[^\/]+$/.test(repository.url), 'repository url not shorthand', repository)
    const [ owner, repo ] = repository.url.split('/')
    const tmp = path.resolve(dir, '.dots')
    return new Dots({ arguable, octokit, owner, repo, dir, json, tmp })
}
