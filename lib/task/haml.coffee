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
    * trace         (Boolean)   > --trace             > Show a full traceback on error
    * unixNewlines  (Boolean)   > --unix-newlines     > Use Unix-style newlines in written files.
    * check         (Boolean)   > --check             > Just check syntax, don't evaluate.
    * escapeHtml    (Boolean)   > --escape-html       > Escape HTML characters (like ampersands
                                                        and angle brackets) by default.
    * doubleQuoteAttributes > --double-quote-attributes > Set attribute wrapper to double-quotes
                                                        (default is single).
    * noEscapeAttrs (Boolean)   > --no-escape-attrs   > Don't escape HTML characters (like
                                                        ampersands and angle brackets) in
                                                        attributes.
    * cdata         (Boolean)   > --cdata             > Always add CDATA sections to javascript
                                                        and css blocks.
    * suppressEval  (Boolean)   > --suppress-eval     > Don't evaluate Ruby scripts.
    * debug         (Boolean)   > --debug             > Print out the precompiled Ruby source.
    * style         (String)    > --style NAME        > Output style. Can be indented (default)
                                                        or ugly.
    * format        (String)    > --format NAME       > Output format. Can be html5 (default),
                                                        xhtml, or html4.
    * autoclose     (String)    > --autoclose LIST    > Comma separated list of elements to be
                                                        automatically self-closed.
    * requires      ([String])  > --require FILE      > Same as 'ruby -r'.
    * loadPaths     ([String])  > --load-path PATH    > Same as 'ruby -I'.




    * -E ex[:in]                       Specify the default external and internal character encodings.

###
module.exports = class Haml extends Abstract

  onRun: (deferred, srcDestMap, options = {}) =>
    options     = _.defaults (options || {}), @getDefaultOptions()
    srcDestObjs = srcDestMap.resolve()
    args        = @prepareArguments(options)

    @_ensureFolders(srcDestObjs, options)

    Q.all(@_execFiles(srcDestObjs, args, options))
    .fail((e) => @_failPromise(deferred, e))
    .done => deferred.resolve()

  getDefaultOptions: =>
    trace:                  true
    unixNewlines:           true
    check:                  false
    escapeHtml:             false
    doubleQuoteAttributes:  false
    noEscapeAttrs:          false
    cdata:                  false
    suppressEval:           false
    debug:                  false

  prepareArguments: (opts = {}) =>
    args = []

    _.each (opts.loadPaths || []), (loadPath) => @_addArgs(args, "--load-path", "#{loadPath}")

    @_addArgs args, "--debug"
    @_addArgs args, "--trace"                   if opts.trace == true
    @_addArgs args, "--debug"                   if opts.debug == true
    @_addArgs args, "--unix-newlines"           if opts.unixNewlines == true
    @_addArgs args, "--check"                   if opts.check == true
    @_addArgs args, "--escape-html"             if opts.escapeHtml == true
    @_addArgs args, "--double-quote-attributes" if opts.doubleQuoteAttributes == true
    @_addArgs args, "--no-escape-attrs"         if opts.noEscapeAttrs == true
    @_addArgs args, "--cdata"                   if opts.cdata == true
    @_addArgs args, "--suppress-eval"           if opts.suppressEval == true

    @_addArgs args, "--style", opts.style               if @_isFilledString(opts.style)
    @_addArgs args, "--format", opts.format             if @_isFilledString(opts.format)
    @_addArgs args, "--autoclose", opts.autoclose       if @_isFilledString(opts.autoclose)
    @_addArgs args, "--requires", opts.requires         if @_isFilledString(opts.requires)

    args

  _execFiles: (srcDestObjs, args, options) =>
    _.map srcDestObjs, (srcDestObj) =>
      d       = Q.defer()
      src     = srcDestObj.src().pathFromRoot()
      output  = srcDestObj.dest().pathFromRoot()
      a       = ['exec', 'haml'].concat(args)
      a       = a.concat([src, output])

      @naspi.exec.exec d, 'bundle', a, {}

      d.promise

  _ensureFolders: (srcDestObjs, options) =>
    _.each srcDestObjs, (srcDestObj) =>
      @naspi.file.mkdir(srcDestObj.dest().dirname())

  _addArgs: (args, newArgs...) =>
    _.each (newArgs || []), (arg) => args.push(arg)

  _isFilledString: (str) =>
    return false unless _.isString(str)

    _.size(str) > 0


