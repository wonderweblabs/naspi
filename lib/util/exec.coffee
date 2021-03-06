_             = require 'lodash'
path          = require 'path'
child_process = require 'child_process'

module.exports = class PackageRunner

  execQueue: []
  currentExecs: []

  constructor: (@naspi) ->

  exec: (deferred, cmd, args, options) =>
    pipeOutput = options.pipeOutput == true

    delete options['pipeOutput']

    @execQueue.push
      uid: _.uniqueId('naspi-exec-')
      deferred: deferred
      cmd: cmd
      args: args
      options: options
      done: false
      pipeOutput: pipeOutput
      output: null

    @_execNext()

  _execNext: =>
    return unless _.any(@execQueue)
    return unless _.size(@currentExecs) < @naspi.option('maxProcesses')

    exec = @execQueue.shift()
    @currentExecs.push exec

    exec.args or= []
    exec.args = [exec.args] unless _.isArray(exec.args) || !exec.args?

    exec.options          or= {}
    exec.options.encoding or= 'utf8'
    exec.options.stdio    or= 'pipe'
    exec.options.env      = _.defaults (exec.options.env || {}), process.env

    @naspi.verbose.write "Exec - "
    @naspi.verbose.writeInfo "#{exec.cmd} #{exec.args.join(' ')}\n"
    @naspi.verbose.writeln '> Pipe output ...' if exec.pipeOutput

    try
      cmdProcess = child_process.spawn(exec.cmd, exec.args, exec.options)
      cmdProcess.stdout.on 'data', (data) => @onExecStdoutData(data, exec)
      cmdProcess.stderr.on 'data', (data) => @onExecStderrData(data, exec)
      cmdProcess.on 'error', (err) => @onExecError(err, exec)
      cmdProcess.on 'exit', (code) => @onExecExit(code, exec)
    catch e
      @naspi.logger.throwError(e.message, e)
      exec.deferred.reject(e)
      @currentExecs = _.without(@currentExecs, exec)
    finally
      @naspi.verbose.write('\n')

  onExecStdoutData: (data, exec) =>
    if exec.pipeOutput
      exec.output = '' unless _.isString(exec.output)
      exec.output += data.toString()
    else
      @naspi.verbose.write(data.toString())

  onExecStderrData: (data, exec) =>
    @naspi.logger.writelnError(data.toString())

  onExecError: (err, exec) =>
    exec.done = true
    @naspi.logger.throwError(err.message, err)
    exec.deferred.reject(err)
    @currentExecs = _.without(@currentExecs, exec)

  onExecExit: (code, exec) =>
    return if exec.done == true
    exec.done = true
    @currentExecs = _.without(@currentExecs, exec)

    if code == 0
      exec.deferred.resolve(exec.output)
      @_execNext()
    else
      @naspi.exit(code)
      exec.deferred.reject()




