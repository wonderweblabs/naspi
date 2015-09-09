Q         = require 'q'
Abstract  = require './abstract'

module.exports = class Bower extends Abstract

  prepare: (env) =>
    @prepared = true
    Q.resolve(env) # already resolved promise

  process: (env) =>
    @processed = true
    Q.resolve(env) # already resolved promise

  postProcess: (env) =>
    @postProcessed = true
    Q.resolve(env) # already resolved promise