_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

###

options:
  * files     (String|[String]) required
  * cwd       (String)
  * destFile  (String) required
  * filter    (function)
  * options
    *

###
module.exports = class Concat extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    options     = _.defaults (options || {}), @getDefaultOptions()
    fileMappings = fileMappingList.resolve()

    @_ensureFolders(fileMappings, options)

    destMapping = {}
    _.each fileMappings, (fileMapping) =>
      destMapping[fileMapping.dest().path()] or= []
      destMapping[fileMapping.dest().path()].push fileMapping

    _.each destMapping, (fileMappings, destFile) =>
      @naspi.file.mkdir(path.dirname(destFile))

      # iterate to final source
      src = _.map(fileMappings, (fileMapping) =>
        @naspi.file.read(fileMapping.src().absolutePath()) ).join('\n')

      # Write
      @naspi.file.write(destFile, src)
      @naspi.verbose.writeln "File \"#{destFile}\" created."

    deferred.resolve()

  getDefaultOptions: ->
    {}

  _ensureFolders: (fileMappings, options) =>
    _.each fileMappings, (fileMapping) =>
      @naspi.file.mkdir(fileMapping.dest().absoluteDirname())

