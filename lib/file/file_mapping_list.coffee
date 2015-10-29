_           = require 'lodash'
path        = require 'path'
FileMapping = require './file_mapping'

module.exports = class FileMappingList

  options:
    cwd:      null
    ext:      null
    extDot:   'first'
    flatten:   false
    expand:    false
    filter:   (list, expandedObj) -> expandedObj
    eachFilter: (fileMapping) -> true

  originalOptions:  null

  filesExpanded:    null

  constructor: (@naspi, options = {}) ->
    [files, options]  = @_normalizeOptions(options)
    @originalOptions  = _.defaults options, {}
    @options          = _.defaults _.pick(options, Object.keys(@options)), @options
    @options.cwd    or= process.cwd()
    @filesExpanded    = []

    if _.isArray(files) then @_prepareFromArr(files) else @_prepareFromObj(files)

    @

  resolve: =>
    fileMappings  = []
    filesExpanded = _.map (@filesExpanded), (expandedObj) => @options.filter(@, expandedObj)

    _.each filesExpanded, (expandedObj) =>
      _.each expandedObj.src, (srcFile) =>
        obj = new FileMapping(@naspi, @, srcFile, expandedObj.dest)
        fileMappings.push(obj) if @options.eachFilter(obj) == true

    fileMappings

  _normalizeOptions: (options) =>
    return [options, {}] if _.isArray(options)

    if _.isString(options.src)
      [{ src: [options.src], dest: options.dest || null }, options ]
    else
      [{ src:  options.src, dest: options.dest || null }, options ]

  _prepareFromArr: (filesArr) =>
    _.each filesArr, (str) =>
      str = str.split(':')
      @filesExpanded.push { src: [str[0]], dest: str[1] }

  _prepareFromObj: (filesObj) =>
    opts      = {}
    opts.cwd  = @options.cwd if _.isString(@options.cwd)
    files     = { src: @naspi.file.expand(opts, filesObj.src), dest: filesObj.dest }
    @filesExpanded = @filesExpanded.concat(files)






