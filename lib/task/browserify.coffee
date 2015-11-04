_             = require 'lodash'
path          = require 'path'
fs            = require 'fs'
Q             = require 'q'
browserify    = require 'browserify'
browserifyInc = require 'browserify-incremental'
xtend         = require 'xtend'
Abstract      = require './abstract'

###

options:
  * options
    * external: [...] as string|array: https://github.com/substack/node-browserify#bexternalfile
    * ignore:   [...] as string|array: https://github.com/substack/node-browserify#bignorefile
    * exclude:  [...] as string|array: https://github.com/substack/node-browserify#bexcludefile
    * coffeeify: true|false - default: true
    * cacheFile: string - default: '#{tmpPath}/browserify-cache.json' - for browserify-incremental
    * sourceMap: true|false - default: false
    * debug:     true|false - default: sourceMap
    * paths:     [string] - look up paths

###
module.exports = class Browserify extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    if _.isArray(options.paths) && _.any(options.paths)
      options.paths = @getDefaultOptions().paths.concat(options.paths)
    else
      delete options.paths

    options       = _.defaults options, @getDefaultOptions()
    fileMappings  = fileMappingList.resolve()

    @_ensureFolders(fileMappings, options)

    Q.all(@_execFiles(fileMappings, options))
    .fail((e) => @_failPromise(deferred, e))
    .done => deferred.resolve()

  getDefaultOptions: =>
    coffeeify: true
    external: []
    ignore:   []
    exclude:  []
    extensions: [".js", ".json"]
    cacheFile: path.join(@naspi.option('tmpPath'), 'browserify-cache.json')
    sourceMap: false
    fullPaths: false
    debug: false
    paths: [
      'node_modules',
      path.join(__dirname, '../..', 'node_modules')
    ]


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _ensureFolders: (fileMappings, options) =>
    _.each fileMappings, (fileMapping) =>
      @naspi.file.mkdir(fileMapping.dest().getAbsoluteDirname())

  # @nodoc
  _execFiles: (fileMappings, options) =>
    _.map fileMappings, (fileMapping) =>
      deferred = Q.defer()

      @_execFile(fileMapping, options)
      .fail((e) => @_failPromise(deferred, e))
      .done => deferred.resolve()

      deferred.promise

  # @nodoc
  _execFile: (fileMapping, options) =>
    deferred  = Q.defer()
    src       = fileMapping.src().absolutePath()
    output    = fileMapping.dest().absolutePath()

    @_runBrowserify(deferred, src, output, options)

    deferred.promise

  # @nodoc
  _runBrowserify: (deferred, src, output, options) =>
    options.extensions.push('.coffee') if options.coffeeify == true

    opts            = {}
    opts.debug      = options.sourceMap
    opts.extensions = options.extensions
    opts.paths      = options.paths

    if _.isString(options.basedir) && !_.isEmpty(options.basedir)
      opts.basedir    = options.basedir

    if options.debug == true || options.sourceMap == true
      opts.cacheFile = options.cacheFile
    # else
    #   opts.fullPaths = false

    b = browserifyInc src, opts

    # option - external
    options.external = [options.external] unless _.isArray(options.external)
    b.external(options.external) if _.any(options.external)

    # option - ignore
    options.ignore = [options.ignore] unless _.isArray(options.ignore)
    b.ignore(options.ignore) if _.any(options.ignore)

    # option - exclude
    options.exclude = [options.exclude] unless _.isArray(options.exclude)
    b.exclude(options.exclude) if _.any(options.exclude)

    # coffee
    b.transform('./node_modules/naspi/node_modules/coffeeify') if options.coffeeify == true

    # build and write
    b.bundle().pipe(fs.createWriteStream(output, 'utf8')).on 'close', =>
      deferred.resolve()





