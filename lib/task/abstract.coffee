_ = require 'lodash'
Q = require 'q'

module.exports = class Abstract

  constructor: (@naspi, @pkg) ->

  run: (env, fileMappingList, options = {}) =>
    deferred = Q.defer()

    @_run(fileMappingList, options, env)
    .fail (e) => deferred.reject(e)
    .done => deferred.resolve(env)

    deferred.promise

  _run: (fileMappingList, options, env) =>
    deferred = Q.defer()
    @onRun(deferred, fileMappingList, options, env)
    deferred.promise

  onRun: (deferred, options, env) =>
    @naspi.logger.throwError("Task - onRun method not implemented.", null)

  _failPromise: (deferred, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)