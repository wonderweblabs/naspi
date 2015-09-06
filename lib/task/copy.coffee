_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

###

options:
  * files   (String|[String]) required
  * cwd     (String)
  * dest    (String) required
  * filter  (function)

###
module.exports = class Copy extends Abstract

  onRun: (deferred, options = {}) =>
    files = @filesExpanded(options)

    _.each files, (file) => @naspi.file.copy(file.src[0], file.dest)

    deferred.resolve()