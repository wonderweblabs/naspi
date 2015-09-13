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

  onRun: (deferred, fileMappingList, options = {}) =>
    fileMappings = fileMappingList.resolve()

    @_ensureFolders(fileMappings, options)

    _.each fileMappings, (fileMapping) =>
      @naspi.file.copy(fileMapping.src().absolutePath(), fileMapping.dest().absolutePath())

    deferred.resolve()

  _ensureFolders: (fileMappings, options) =>
    _.each fileMappings, (fileMapping) =>
      @naspi.file.mkdir(fileMapping.dest().absoluteDirname())