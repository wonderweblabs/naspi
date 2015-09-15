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
  * options
    * cacheLocation (String)        > --cache-location > The path to save parsed Sass files.
                                                      Defaults to .sass-cache.
    * loadPaths (String|[String])   > --load-path   > Specify a Sass import path.
    * style     (String)            > --style       > Output style. Can be nested (default),
                                                      compact, compressed, or expanded.
    * update    (Boolean)           > --update      > Compile only changed files
    * sourcemap (String)            > --sourcemap   > How to link generated output to the
                                                      source files.
                                                        auto (default): relative paths where
                                                                        possible, file URIs
                                                                        elsewhere
                                                        file: always absolute file URIs
                                                        inline: include the source text in
                                                                the sourcemap
                                                        none: no sourcemaps
    * encoding  (String)            > --default-encoding > Specify the default encoding for
                                                      input files.
    * precision (Integer)           > --precision   > How many digits of precision to use when
                                                      outputting decimal numbers. Defaults to 5.
    * noCache   (Boolean)           > --no-cache    > Don't cache parsed Sass files.
    * trace     (Boolean)           > --trace       > Show a full Ruby stack trace on error.
    * quiet     (Boolean)           > --quiet       > Silence warnings and status messages
                                                      during compilation.

###
module.exports = class Sass extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    options       = _.defaults (options || {}), @getDefaultOptions()
    fileMappings  = fileMappingList.resolve()
    args          = @prepareArguments(options)

    @_ensureFolders(fileMappings, options)

    Q.all(@_execFiles(fileMappings, args, options))
    .fail((e) => @_failPromise(deferred, e))
    .done => deferred.resolve()

  getDefaultOptions: =>
    cacheLocation: @naspi.option('sassCache')
    style: 'expanded'
    update: true
    sourcemap: 'auto'
    encoding: 'UTF-8'
    precision: 10
    noCache: false
    trace: false
    quiet: true

  prepareArguments: (opts = {}) =>
    args = ["--stop-on-error"]

    _.each (opts.loadPaths || []), (loadPath) => @_addArgs(args, "--load-path", "#{loadPath}")
    @_addArgs args, "--cache-location", opts.cacheLocation
    @_addArgs args, "--style", opts.style
    @_addArgs args, "--sourcemap=#{opts.sourcemap}"
    @_addArgs args, "--default-encoding", opts.encoding
    @_addArgs args, "--precision", opts.precision
    @_addArgs args, "--update"   if opts.update == true
    @_addArgs args, "--no-cache" if opts.noCache == true
    @_addArgs args, "--trace"    if opts.trace == true
    @_addArgs args, "--quiet"    if opts.quiet == true

    args

  _execFiles: (fileMappings, args, options) =>
    sass = require 'node-sass'

    loadPaths = options.loadPaths || []

    _.map fileMappings, (fileMapping) =>
      d     = Q.defer()
      src   = fileMapping.src().absolutePath()
      dest  = fileMapping.dest().absolutePath()

      sass.render({
        file:           src
        outFile:        dest
        outputStyle:    'expanded'
        precision:      10
        sourceComments: false
        sourceMap:      false
        includePaths:   loadPaths
        indentType:     'space'
        indentWidth:    2
      }, (err, result) =>
        if err
          console.log err, result
        else
          @naspi.file.write(dest, result.css)
          d.resolve()
      )

      d.promise

    # sass.render({
    #   file: scss_filename,
    #   [, options..]
    # }, function(err, result) { /*...*/ });

    # file
    # outFile
    # outputStyle # nested, expanded, compact, compressed
    # precision # 5
    # sourceComments: # false
    # sourceMap: # false


    # _.map fileMappings, (fileMapping) =>
    #   d     = Q.defer()
    #   src   = fileMapping.src().absolutePath()
    #   dest  = fileMapping.dest().absolutePath()
    #   a     = ["exec", "sass"].concat(args)
    #   a     = a.concat(["#{src}:#{dest}"])

    #   @naspi.exec.exec d, 'bundle', a, {}

    #   d.promise

  _ensureFolders: (fileMappings, options) =>
    @naspi.file.mkdir(options.cacheLocation)
    _.each fileMappings, (fileMapping) =>
      @naspi.file.mkdir(fileMapping.dest().absoluteDirname())

  _addArgs: (args, newArgs...) =>
    _.each (newArgs || []), (arg) => args.push(arg)

