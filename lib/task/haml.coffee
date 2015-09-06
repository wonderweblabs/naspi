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
    * namespace       (String)      > --namespace       > Set a custom template namespace
                                                          [default: "window.HAML"]
    * template        (String)      > --template        > Set a custom template name
    * basename        (Boolean)     > --basename        > Ignore file path when generate the
                                                          template name [default: false]
    * format          (String)      > --format          > Set HTML output format, either `xhtml`,
                                                          `html4` or `html5`  [default: "html5"]
    * uglify          (Boolean)     > --uglify          > Do not properly indent or format the HTML
                                                          output [default: false]
    * extend          (Boolean)     > --extend          > Extend the template scope with the
                                                          context [default: false]
    * placement       (String)      > --placement       > Where to place the template function;
                                                          one of: global, amd [default: "global"]
    * dependencies    (Json String) > --dependencies    > The global template amd module
                                                          dependencies
                                                          [default: "{ hc: 'hamlcoffee' }"]
    * render          (Boolean)     > --render          > Render the template into static HTML
                                                          [default: false]
    * preserve        (String)      > --preserve        > Set a comma separated list of HTML tags
                                                          to preserve [default: "pre,textarea"]
    * autoclose       (String)      > --autoclose       > Set a comma separated list of self-closed
                                                          HTML tags [default: "meta,img,link,br,hr,
                                                          input,area,param,col,base"]
    * hyphenateDataAttrs            (Boolean) > --hyphenate-data-attrs
                                                        > Convert underscores to hyphens for data
                                                          attribute keys
    * disableHtmlAttributeEscaping  (Boolean) > --disable-html-attribute-escaping
                                                        > Disable any HTML attribute escaping
                                                          [default: true]
    * disableHtmlEscaping           (Boolean) > --disable-html-escaping
                                                        > Disable any HTML escaping
    * disableCleanValue             (Boolean) > --disable-clean-value
                                                        > Disable any CoffeeScript code value
                                                          cleaning

###
module.exports = class Haml extends Abstract

  onRun: (deferred, options = {}) =>
    options.options = _.defaults (options.options || {}), @getDefaultOptions()
    files           = @filesExpanded(options)
    args            = @prepareArguments(options.options)

    @_ensureFolders(files, options)

    Q.all(@_execFiles(files, args, options)).done(=> deferred.resolve())

  getDefaultOptions: =>
    basename: false
    uglify:   false
    extend:   false
    render:   false
    hyphenateDataAttrs:           false
    disableHtmlAttributeEscaping: false
    disableHtmlEscaping:          false
    disableCleanValue:            false

  prepareArguments: (opts = {}) =>
    args = []

    @_addArgs args, "--basename"  if opts.basename == true
    @_addArgs args, "--uglify"    if opts.uglify == true
    @_addArgs args, "--extend"    if opts.extend == true
    @_addArgs args, "--render"    if opts.render == true
    @_addArgs args, "--hyphenate-data-attrs"            if opts.hyphenateDataAttrs == true
    @_addArgs args, "--disable-html-attribute-escaping" if opts.disableHtmlAttributeEscaping == true
    @_addArgs args, "--disable-html-escaping"           if opts.disableHtmlEscaping == true
    @_addArgs args, "--disable-clean-value"             if opts.disableCleanValue == true

    @_addArgs args, "--namespace", opts.namespace       if @_isFilledString(opts.namespace)
    @_addArgs args, "--template", opts.template         if @_isFilledString(opts.template)
    @_addArgs args, "--format", opts.format             if @_isFilledString(opts.format)
    @_addArgs args, "--placement", opts.placement       if @_isFilledString(opts.placement)
    @_addArgs args, "--dependencies", opts.dependencies if @_isFilledString(opts.dependencies)
    @_addArgs args, "--preserve", opts.preserve         if @_isFilledString(opts.preserve)
    @_addArgs args, "--autoclose", opts.autoclose       if @_isFilledString(opts.autoclose)

    args

  _execFiles: (files, args, options) =>
    _.map files, (file) =>
      d       = Q.defer()
      src     = path.join(process.cwd(), file.src[0])
      output  = path.join(process.cwd(), file.dest.replace(/\.haml$/, ''))
      a       = args.concat(["--output", output, "--input", src])
      cmd     = './node_modules/haml-coffee/bin/haml-coffee'
      cmd     = path.relative(@pkg.basePath, cmd)

      @naspi.exec.exec cmd, a, { cwd: @pkg.basePath }, => d.resolve()

      d.promise

  _ensureFolders: (files, options) =>
    _.each files, (file) => @naspi.file.mkdir(path.dirname(file.dest))

  _addArgs: (args, newArgs...) =>
    _.each (newArgs || []), (arg) => args.push(arg)

  _isFilledString: (str) =>
    return false unless _.isString(str)

    _.size(str) > 0


