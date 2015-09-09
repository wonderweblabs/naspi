_         = require 'lodash'
path      = require 'path'

module.exports = class FileMapping

  cwd:      null
  ext:      null
  extDot:   null
  flatten:  false

  srcFile:  null
  descFile: null

  constructor: (@naspi, @map, src, dest) ->
    @setSrc(src)
    @setDest(dest)

    @cwd      = @map.options.cwd
    @ext      = @map.options.ext
    @extDot   = @map.options.extDot
    @flatten  = @map.options.flatten
    @expand   = @map.options.expand

    @_prepareDestFile()


  src: => @srcFile
  getSrc: => @src()
  setSrc: (src) => @srcFile = new File(@naspi, @, src, false)

  dest: => @descFile
  getDest: => @dest()
  setDest: (dest) => @descFile = new File(@naspi, @, dest, true)

  _prepareDestFile: =>
    destFile = if @expand is true then path.join(@dest().path(), @src().basename()) else @dest().path()
    dir      = path.dirname(destFile)
    base     = path.basename(destFile)

    if _.isString(@ext) && _.size(@ext) > 0
      if @extDot == 'first'
        base = [base.split('.')[0], @ext]
      else
        base = base.split('.')
        base.pop()
        base.push(ext)
    else
      base = [base]

    @setDest(path.join(dir, base.join('.')))

  class File

    p:      null
    isAbs:  false

    constructor: (@naspi, @fm, @p, @isDest) ->
      @isAbs = @naspi.file.isPathAbsolute(@p)

    path: =>            @p
    pathFromRoot: =>    if @isAbs || @isDest then @path() else path.join(@fm.cwd, @path())
    dirname: =>         path.dirname(@path())
    basename: =>        path.basename(@path())

    exists: =>          @naspi.file.exists(@pathFromRoot())
    isLink: =>          @naspi.file.isLink(@pathFromRoot())
    isDir: =>           @naspi.file.isDir(@pathFromRoot())
    isFile: =>          @naspi.file.isFile(@pathFromRoot())
    isPathAbsolute: =>  @isAbs
    isPathCwd: =>       @naspi.file.isPathCwd(@pathFromRoot())
    isPathInCwd: =>     @naspi.file.isPathInCwd(@pathFromRoot())

    hasChanged: (cacheKey = 'file') =>
      @naspi.file.changeTracker.hasChanged(@pathFromRoot(), cacheKey)

    updateChangedState: (cacheKey = 'file') =>
      @naspi.file.changeTracker.update(@pathFromRoot(), cacheKey)

    cleanChangedState: (cacheKey = 'file') =>
      @naspi.file.changeTracker.clean(@pathFromRoot(), cacheKey)





