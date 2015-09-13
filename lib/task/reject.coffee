_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

module.exports = class Sass extends Abstract

  constructor: (@naspi, @pkg, @error) ->

  onRun: (deferred, fileMappingList, options = {}) =>
    deferred.reject(@error)
    deferred.promise