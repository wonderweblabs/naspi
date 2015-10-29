_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

###

options:
  * patterns [{ pattern, replacement }]

###
module.exports = class Replace extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    options       = _.defaults (options || {}), @getDefaultOptions()
    fileMappings  = fileMappingList.resolve()

    @_ensureFolders(fileMappings, options)

    @_execFiles(fileMappings, options)
    deferred.resolve()

  getDefaultOptions: =>
    patterns: []


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _execFiles: (fileMappings, options) =>
    _.each fileMappings, (fileMapping) =>
      if _.isArray(options.patterns) && _.any(options.patterns)
        @_replace(fileMapping, options)

  # @nodoc
  _replace: (fileMapping, options) =>
    src       = fileMapping.src().absolutePath()
    output    = fileMapping.dest().absolutePath()
    content   = @naspi.file.read(src)

    _.each options.patterns, (pattern) =>
      return if _.isNull(pattern.pattern) || _.isNull(pattern.replacement)
      return if _.isUndefined(pattern.pattern) || _.isUndefined(pattern.replacement)

      content = content.replace(pattern.pattern, pattern.replacement)

    @naspi.file.write output, content

  # @nodoc
  _ensureFolders: (fileMappings, options) =>
    _.each fileMappings, (fileMapping) =>
      @naspi.file.mkdir(fileMapping.dest().absoluteDirname())