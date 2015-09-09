_ = require 'lodash'
Q = require 'q'

module.exports = class Abstract

  constructor: (@naspi, @pkg) ->

  run: (srcDestMap, options = {}) =>
    deferred = Q.defer()

    @onRun(deferred, srcDestMap, options)

    deferred.promise

  onRun: (deferred, options = {}) =>
    @naspi.logger.throwError("Task - onRun method not implemented.", null)

  _failPromise: (deferred, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)