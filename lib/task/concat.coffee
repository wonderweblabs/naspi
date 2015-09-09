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

  onRun: (deferred, srcDestMap, options = {}) =>
    options     = _.defaults (options || {}), @getDefaultOptions()
    srcDestObjs = srcDestMap.resolve()

    destMapping = {}
    _.each srcDestObjs, (srcDestObj) =>
      destMapping[srcDestObj.dest().path()] or= []
      destMapping[srcDestObj.dest().path()].push srcDestObj

    _.each destMapping, (srcDestObjs, destFile) =>
      @naspi.file.mkdir(path.dirname(destFile))

      # iterate to final source
      src = _.map(srcDestObjs, (srcDestObj) =>
        @naspi.file.read(srcDestObj.src().pathFromRoot()) ).join('\n')

      # Write
      @naspi.file.write(destFile, src)
      @naspi.verbose.writeln "File \"#{destFile}\" created."

    deferred.resolve()

  getDefaultOptions: ->
    {}

