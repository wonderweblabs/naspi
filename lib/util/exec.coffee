_             = require 'lodash'
path          = require 'path'
child_process = require 'child_process'

module.exports = class PackageRunner

  constructor: (@naspi) ->

  exec: (cmd, args, options, callback) =>
    options.encoding  or= 'utf8'
    args = [args] unless _.isArray(args) || !args?

    @naspi.verbose.write "Exec - "
    @naspi.verbose.writeInfo "#{cmd} #{args.join(' ')}\n"

    cmdProcess = child_process.spawn(cmd, args, options)
    cmdProcess.stdout.on 'data', (data) => @onExecStdoutData(data, cmd, args, options)
    cmdProcess.stderr.on 'data', (data) => @onExecStderrData(data, cmd, args, options)
    cmdProcess.on 'error', (err) => @onExecError(err, cmd, args, options, callback)
    cmdProcess.on 'close', (code) => @onExecClose(code, cmd, args, options, callback)

  onExecStdoutData: (data, cmd, args, options) =>
    @naspi.verbose.writeln data.toString()

  onExecStderrData: (data, cmd, args, options) =>
    @naspi.logger.writelnError ''
    @naspi.logger.writelnError ''
    @naspi.logger.writelnError data.toString()
    @naspi.logger.writelnError ''

  onExecError: (err, cmd, args, options, callback) =>
    @naspi.logger.throwError(err.message, err)

  onExecClose: (code, cmd, args, options, callback) =>
    if code == 0
      callback() if _.isFunction(callback)
    else
      @naspi.exit(code)