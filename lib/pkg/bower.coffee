Q         = require 'q'
Abstract  = require './abstract'

module.exports = class Bower extends Abstract

  prepare: =>
    @prepared = true
    Q.resolve() # already resolved promise

  process: =>
    @processed = true
    Q.resolve() # already resolved promise

  postProcess: =>
    @postProcessed = true
    Q.resolve() # already resolved promise