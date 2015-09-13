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
    chain = Q(@env)
    _.each @steps, (stepFunc) => chain = chain.then stepFunc if _.isFunction(stepFunc)
    chain.fail (error) => @failCb(@deferred, @env, error)
    chain.done => @doneCb(@deferred, @env)

    @promise()

  done: (func) =>
    @failCb = func

  fail: (func) =>
    @doneCb = func


  # ----------------------------------------------------------
  # private

  # @nodoc
  _failCb: (deferred, env, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)

  # @nodoc
  _doneCb: (deferred, env) =>
    deferred.resolve(env)