Q         = require 'q'
Abstract  = require './abstract'

module.exports = class Bower extends Abstract

  prepare: (options = {}) =>
    @prepared = true
    Q() # already resolved promise

  process: (options = {}) =>
    @processed = true
    Q() # already resolved promise

  postProcess: (options = {}) =>
    @postProcessed = true
    Q() # already resolved promise