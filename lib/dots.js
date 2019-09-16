const assert = require('assert')
const Octokit = require('@octokit/rest')
const fs = require('fs').promises
const path = require('path')
const once = require('prospective/once')
const stream = require('stream')
const children = require('child_process')

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

    async zsh (zsh, ...vargs) {
        const child = children.spawn(zsh, vargs, {
            shell: 'zsh',
            stdio: [ 'inherit', 'inherit', 'inherit', 'pipe' ]
        })
        const output = new stream.PassThrough({ encoding: 'utf8' })
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
