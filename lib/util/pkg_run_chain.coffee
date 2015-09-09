_     = require 'lodash'
path  = require 'path'
Q     = require 'q'

module.exports = class PkgRunChain

  deferred: null
  steps: null
  failCb: null
  doneCb: null

  constructor: (@naspi, @env, deferred = null) ->
    @deferred = deferred || Q.defer()
    @steps    = []
    @failCb   = @_failCb
    @doneCb   = @_doneCb

  promise: =>
    @deferred.promise

  addStep: (func) =>
    @steps.push func

  process: =>
    deferred = Q.defer()
    deferred.promise.fail (error) => @failCb(@deferred, @env, error)
    deferred.promise.done => @doneCb(@deferred, @env)

    _.each @steps, (stepFunc) => deferred.promise.then(stepFunc)

    deferred.resolve(@env)
    @promise()

  done: (func) =>
    @failCb = func

  fail: (func) =>
    @doneCb = func


  # ----------------------------------------------------------
  # private - files

  # @nodoc
  _failCb: (deferred, env, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)

  # @nodoc
  _doneCb: (deferred, env) =>
    deferred.resolve(env)