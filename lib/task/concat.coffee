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

  onRun: (deferred, options = {}) =>
    options.options = _.defaults (options.options || {}), @getDefaultOptions()

    # load files
    opts        = {}
    opts.cwd    = options.cwd if _.isString(options.cwd) && !_.isEmpty(options.cwd)
    opts.filter = options.filter if _.isFunction(options.filter)
    files       = @naspi.file.expand(opts, options.files)

    @_ensureFolders(files, options)

    # iterate to final source
    src = _.map(files, (file) => @naspi.file.read(path.join((options.cwd || ''), file)) ).join('\n')

    # Write
    @naspi.file.write(options.destFile, src)
    @naspi.verbose.writeln "File \"#{options.destFile}\" created."
    deferred.resolve()

  getDefaultOptions: ->
    {}

  _ensureFolders: (files, options) =>
    @naspi.file.mkdir(path.dirname(options.destFile))