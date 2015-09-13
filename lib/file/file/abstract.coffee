_         = require 'lodash'
path      = require 'path'

module.exports = class AbstractFile

  options:
    basename: null    # file name
    orgPath:  null    # Passed path
    relPath:  null    # Relative path to cwd
    absPath:  null    # Absolute path
    cwd:      null    # cwd or process.cwd()
    ext:      null    # If set, the file extension of orgPath will be changed
    extDot:   null    # 'first' or 'last' > where to split the file name
    flatten:  false   # Remove relative path > in relation to cwd
    isAbs:    false   # If original has been absolute
    expand:   false   # see DestFile

  constructor: (@naspi, file, options = {}) ->
    @options = _.defaults options, @options
    @_processData(file)

  # states

  isAbsolute: => @options.isAbs

  isFlattened: => @options.flatten

  isExtChanged: => _.isString(@options.ext) && _.size(@options.ext) > 0

  # paths

  getPath: => if @isAbsolute() then @options.absPath else @options.relPath
  path: => @getPath()

  getOriginalPath: => @options.orgPath
  originalPath: => @getOriginalPath()

  getRelativePath: => @options.relPath
  relativePath: => @getRelativePath()

  getAbsolutePath: => @options.absPath
  absolutePath: => @getAbsolutePath()

  # meta

  getCwd: => @options.cwd
  cwd: => @getCwd()

  getBasename: => @options.basename
  basename: => @getBasename()

  getDirname: => path.dirname(@getPath())
  dirname: => @getDirname()

  getRelativeDirname: => path.dirname(@getRelativePath())
  relativeDirname: =>@getRelativeDirname()

  getAbsoluteDirname: => path.dirname(@getAbsolutePath())
  absoluteDirname: => @getAbsoluteDirname()

  # file checks

  exists: =>          @naspi.file.exists(@getAbsolutePath())
  isLink: =>          @naspi.file.isLink(@getAbsolutePath())
  isDir: =>           @naspi.file.isDir(@getAbsolutePath())
  isFile: =>          @naspi.file.isFile(@getAbsolutePath())
  isPathInCwd: =>     @naspi.file.isPathInCwd(@getAbsolutePath())

  # change tracker

  hasChanged: (cacheKey = 'file') =>
    @naspi.file.changeTracker.hasChanged(@getAbsolutePath(), cacheKey)

  updateChangedState: (cacheKey = 'file') =>
    @naspi.file.changeTracker.update(@getAbsolutePath(), cacheKey)

  cleanChangedState: (cacheKey = 'file') =>
    @naspi.file.changeTracker.clean(@getAbsolutePath(), cacheKey)


  # ----------------------------------------------------------
  # private - files

  # @nodoc
  _processData: (file) =>

    # ensure cwd
    @options.cwd or= process.cwd()

    # file abs?
    @options.isAbs = path.isAbsolute(file)

    # basename
    @options.basename = path.basename(file)

    # set paths
    @options.orgPath = file
    @options.relPath = @_processRelPath()
    @options.absPath = path.resolve(@options.cwd, @options.relPath)

    # rename if necessary
    @_processRenaming() if _.isString(@options.ext) && _.size(@options.ext) > 0

    # process flatten
    @_processFlatten() if @options.flatten == true

  # @nodoc
  _processRelPath: =>
    return @options.orgPath if @options.isAbs is false

    dir = path.relative(@options.cwd, path.dirname(@options.orgPath))
    path.join(dir, @options.basename).replace(/^\//, '')

  # @nodoc
  _processRenaming: =>
    extDot  = @options.extDot || 'last'
    base    = path.basename(@options.orgPath)
    base    = base.split('.')

    if extDot == 'first'
      base = [base[0], @options.ext]
    else
      base.pop()
      base.push(@options.ext)

    @options.basename = base.join('.')
    @options.relPath  = path.join(path.dirname(@options.relPath), @options.basename)
    @options.absPath  = path.join(path.dirname(@options.absPath), @options.basename)

  # @nodoc
  _processFlatten: =>
    @options.relPath = @options.basename.replace(/^\//, '')
    @options.absPath = path.resolve(@options.cwd, @options.relPath)




