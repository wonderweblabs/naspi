_         = require 'lodash'
path      = require 'path'
url       = require('url')
Q         = require 'q'
Abstract  = require './abstract'

###

options:
  * abspath         (String)    > --abspath <arg>     > use <arg> as the "webserver root", make all
                                                        adjusted urls absolute
  * inlineScripts   (Boolean)   > --inline-scripts    > Inline external scripts
  * inlineCss       (Boolean)   > --inline-css        > Inline external stylesheets
  * excludes        ([String])  > --exclude <path>    > exclude a subpath from root. Use multiple
                                                        times to exclude multiple paths. Tags to
                                                        excluded paths are kept.
  * stripExcludes   ([String])  > --strip-exclude     > Exclude a subpath and remove any links
                                                        referencing it.
  * stripComments   (Boolean)   > --strip-comments    > Strips all HTML comments not containing
                                                        an @license from the document

###
module.exports = class Vulcanize extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    options       = _.defaults (options || {}), @getDefaultOptions()
    fileMappings  = fileMappingList.resolve()
    args          = @prepareArguments(options)
    console.log 'VULCANIZE', _.map fileMappings, (fileMapping) => fileMapping.src().path()

    @_ensureFolders(fileMappings, options)

    Q.all(@_execFiles(fileMappings, args, options))
    .fail((e) => @_failPromise(deferred, e))
    .done => deferred.resolve()

  prepareArguments: (opts = {}) =>
    args = []

    if _.isArray(opts.excludes)
      _.each opts.excludes, (exclude) =>
        @_addArgs(args, "--exclude", "#{exclude}")

    if _.isArray(opts.stripExcludes)
      _.each opts.stripExcludes, (stripExclude) =>
        @_addArgs(args, "--strip-exclude", "#{stripExclude}")

    @_addArgs args, "--abspath"         if @_isFilledString(opts.abspath)
    @_addArgs args, "--inline-scripts"  if opts.inlineScripts == true
    @_addArgs args, "--inline-css"      if opts.inlineCss == true
    @_addArgs args, "--strip-comments"  if opts.stripComments == true

    args

  getDefaultOptions: =>
    inlineScripts:  true
    inlineCss:      true
    stripComments:  false
    abspath:        null
    excludes:       []
    stripExcludes:  []


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _ensureFolders: (fileMappings, options) =>
    _.each fileMappings, (fileMapping) =>
      @naspi.file.mkdir(fileMapping.dest().absoluteDirname())

  # @nodoc
  _addArgs: (args, newArgs...) =>
    _.each (newArgs || []), (arg) => args.push(arg)

  # @nodoc
  _isFilledString: (str) =>
    return false unless _.isString(str)

    _.size(str) > 0

  # @nodoc
  _execFiles: (fileMappings, args, options) =>
    _.map fileMappings, (fileMapping) =>
      deferred = Q.defer()

      @_execFile(fileMapping, args, options)
      .then (fileContent) => @_writeFile(fileMapping, args, options, fileContent)
      .fail((e) => @_failPromise(deferred, e))
      .done => deferred.resolve()

      deferred.promise

  # @nodoc
  _execFile: (fileMapping, args, options) =>
    deferred  = Q.defer()
    src       = fileMapping.src().absolutePath()
    output    = fileMapping.dest().absolutePath()
    a         = args.concat([src])

    @naspi.exec.exec(deferred, 'vulcanize', a, { pipeOutput: true })

    deferred.promise

  # @nodoc
  _writeFile: (fileMapping, args, options, fileContent) =>
    output = fileMapping.dest().absolutePath()

    @naspi.file.write(output, fileContent)




