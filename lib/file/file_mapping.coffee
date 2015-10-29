_         = require 'lodash'
path      = require 'path'
SrcFile   = require './file/src_file'
DestFile  = require './file/dest_file'

module.exports = class FileMapping

  cwd:      null
  ext:      null
  extDot:   null
  flatten:  false

  srcFile:  null
  descFile: null

  constructor: (@naspi, @map, src, dest) ->
    @_inputSrc  = src
    @_inputDest = dest

    @cwd      = @map.options.cwd
    @ext      = @map.options.ext
    @extDot   = @map.options.extDot
    @flatten  = @map.options.flatten
    @expand   = @map.options.expand

    @setSrc(@_inputSrc)

  src: => @srcFile
  getSrc: => @src()
  setSrc: (src) =>
    @srcFile = new SrcFile(@naspi, src, @_srcFileOptions())
    @setDest(@_inputDest)

  dest: => @descFile
  getDest: => @dest()
  setDest: (dest) =>
    @descFile = new DestFile(@naspi, dest, @srcFile, @_destFileOptions())


  # ----------------------------------------------------------
  # private - files

  # @nodoc
  _srcFileOptions: =>
    opts = {}
    opts.cwd = @cwd if _.isString(@cwd) && _.size(@cwd) > 0
    opts

  # @nodoc
  _destFileOptions: =>
    opts = {}
    opts.ext      = @ext      if _.isString(@ext) && _.size(@ext) > 0
    opts.extDot   = @extDot   if _.isString(@extDot) && _.size(@extDot) > 0
    opts.flatten  = @flatten  if _.isBoolean(@flatten)
    opts.expand   = @expand   if _.isBoolean(@expand)
    opts





