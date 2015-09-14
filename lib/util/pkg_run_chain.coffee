_     = require 'lodash'
path  = require 'path'
Q     = require 'q'

module.exports = class PkgRunChain

  deferred: null
  steps: null
  failCb: null
  doneCb: null

  constructor: (@naspi, deferred = null) ->
    @deferred = deferred || Q.defer()
    @steps    = []
    @failCb   = @_failCb
    @doneCb   = @_doneCb

  promise: =>
    @deferred.promise

  addStep: (func) =>
    @steps.push func

  process: =>
    chain = Q()
    _.each @steps, (stepFunc) => chain = chain.then stepFunc if _.isFunction(stepFunc)
    chain.fail (error) => @failCb(@deferred, error)
    chain.done => @doneCb(@deferred)

    @promise()

  done: (func) =>
    @failCb = func

  fail: (func) =>
    @doneCb = func


  # ----------------------------------------------------------
  # private

  # @nodoc
  _failCb: (deferred, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)

  # @nodoc
  _doneCb: (deferred) =>
    deferred.resolve()