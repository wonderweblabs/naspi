_         = require 'lodash'
path      = require 'path'
url       = require 'url'
Q         = require 'q'
Fs        = require 'fs'
crypto    = require 'crypto'
convert   = require 'convert-source-map'
Abstract  = require './abstract'

###

###
module.exports = class Filerev extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    @_options = _.defaults (options || {}), @getDefaultOptions()

    @_readMappingFile()

    fileMappings = @resolveFiles(fileMappingList)
    fileMappings = @filterRevisionedFiles(fileMappings)

    @dropOldRevisionFiles(fileMappings)
    @createRevisionFiles(fileMappings)
    @updateSourceMapLink(fileMappings)

    @_writeMappingFile()
    deferred.resolve()

  # -----

  getDefaultOptions: =>
    digest: false

  getFilerevFile: =>
    @naspi.option('filerevFile')

  getMapping: =>
    @_mapping or= @_readMappingFile()

  getHashLength: =>
    @_hashLength or= 64

  getRevisionedFileRegex: =>
    @_revisionedFileRegex or= new RegExp("\.[a-zA-Z0-9]{#{@getHashLength()}}\.")

  withDigest: =>
    @_options.digest == true

  # -----

  resolveFiles: (fileMappingList) =>
    fileMappingList.resolve()

  filterRevisionedFiles: (fileMappings) =>
    _.filter fileMappings, (fileMapping) =>
      @getRevisionedFileRegex().test(fileMapping.src().path()) == false

  # -----

  dropOldRevisionFiles: (fileMappings) =>
    return unless @withDigest() == true

    _.each fileMappings, (fileMapping) =>
      file  = fileMapping.src().absolutePath()
      f     = @getMapping()[file]

      return if _.isUndefined(f)
      return if _.isNull(f)
      return if f == file
      return unless @naspi.file.exists(f)

      @naspi.file.delete(f, { force: true })

  createRevisionFiles: (fileMappings) =>
    _.each fileMappings, (fileMapping) =>
      return unless fileMapping.src().isFile()

      if @withDigest() == true
        newPath = @_digestPath(fileMapping.src().absolutePath())
        @naspi.file.copy(fileMapping.src().absolutePath(), newPath)
      else
        newPath = fileMapping.src().absolutePath()

      @getMapping()[fileMapping.src().absolutePath()] = newPath

  updateSourceMapLink: (fileMappings) =>
    _.each fileMappings, (fileMapping) =>
      file            = fileMapping.src().absolutePath()
      sourceMapPath   = "#{file}.map"
      resultFilePath  = @getMapping()[file]

      return if _.isUndefined(resultFilePath)
      return if _.isUndefined(sourceMapPath)
      return if _.isNull(resultFilePath)
      return if _.isNull(sourceMapPath)
      return unless @naspi.file.exists(resultFilePath)
      return unless @naspi.file.exists(sourceMapPath)

      fileContents  = @naspi.file.read(resultFilePath, { encoding: 'utf8' })
      matches       = convert.mapFileCommentRegex.exec(fileContents)

      return unless matches

      sourceMapFile = matches[1] || matches[2]
      newSrcMap     = fileContents.replace sourceMapFile, path.basename(sourceMapPath)

      @naspi.file.write resultFilePath, newSrcMap, { encoding: 'utf8' }


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _readMappingFile: ->
    return {} unless @naspi.file.exists(@getFilerevFile())

    try
      @_mapping = @naspi.file.readJSON(@getFilerevFile())
    catch e
      @_mapping = {}

    @_mapping or= {}
    @_mapping

  # @nodoc
  _writeMappingFile: ->
    @naspi.file.writeJSON @getFilerevFile(), @_mapping, { prettyPrint: true }

  # @nodoc
  _digestPath: (file) ->
    hash = crypto.createHash('sha256').update(Fs.readFileSync(file)).digest('hex')
    hash = hash.slice(0, 64)

    fileData = path.parse(file)

    if /(css\.map)$/.test(file)
      newFileName = file.replace(/css\.map$/, '')
      newFileName += "#{hash}.css.map"
      return newFileName
    else if /(js\.map)$/.test(file)
      newFileName = file.replace(/js\.map$/, '')
      newFileName += "#{hash}.js.map"
      return newFileName
    else
      newFileName = "#{fileData.name}.#{hash}#{fileData.ext}"
      return path.join(fileData.dir, newFileName)


