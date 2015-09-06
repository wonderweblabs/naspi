_ = require 'lodash'
Q = require 'q'

module.exports = class Abstract

  constructor: (@naspi, @pkg) ->

  run: (options = {}) =>
    deferred = Q.defer()

    @onRun(deferred, options)

    deferred.promise

  onRun: (deferred, options = {}) =>
    @naspi.logger.throwError("Task - onRun method not implemented.", null)

  filesExpanded: (options = {}) =>
    opts        = {}
    opts.cwd    = options.cwd if _.isString(options.cwd) && !_.isEmpty(options.cwd)
    opts.filter = options.filter if _.isFunction(options.filter)

    @naspi.file.expandMapping(options.files, options.dest, opts)