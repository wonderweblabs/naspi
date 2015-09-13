_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

###

###
module.exports = class Filerev extends Abstract

  onRun: (deferred, fileMappingList, options = {}) =>
    @_options = _.defaults (options || {}), @getDefaultOptions()

    @_readFilerevFile()
    @_readManifestFile()

    mapping = @parseMapping()
    @updateManifest(mapping)

    @_writeManifestFile()
    deferred.resolve()

  # -----

  getDefaultOptions: =>
    {}

  getFilerevFile: =>
    @naspi.option('filerevFile')

  getManifestFile: =>
    @naspi.option('manifestFile')

  getMapping: =>
    @_mapping or= @_readManifestFile()

  getFilerev: =>
    @_filerevMapping or= @_readFilerevFile()

  # -----

  parseMapping: =>
    _.inject @getFilerev(), {}, (memo, resultPath, file) =>
      cwd       = @naspi.option('manifestSrcCwd') || ''
      cwd       = path.join(process.cwd(), cwd) if !@naspi.file.isPathAbsolute(cwd)
      srcPath   = path.relative(cwd, file)
      return memo if _.isEmpty(srcPath)

      cwd       = @naspi.option('manifestDestCwd') || ''
      cwd       = path.join(process.cwd(), cwd) if !@naspi.file.isPathAbsolute(cwd)
      destPath  = path.relative(cwd, resultPath)
      return memo if _.isEmpty(destPath)

      srcPath       = srcPath.replace(/^(\/)/, '')
      memo[srcPath] = destPath
      memo

  updateManifest: (mapping) =>
    _.each mapping, (resultPath, path) =>
      @getMapping()[path] = resultPath


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _readManifestFile: =>
    return {} unless @naspi.file.exists(@getManifestFile())

    try
      @_mapping = @naspi.file.readJSON(@getManifestFile())
    catch e
      @_mapping = {}

    @_mapping or= {}
    @_mapping

  # @nodoc
  _readFilerevFile: =>
    return {} unless @naspi.file.exists(@getFilerevFile())

    try
      @_filerevMapping = @naspi.file.readJSON(@getFilerevFile())
    catch e
      @_filerevMapping = {}

    @_filerevMapping or= {}
    @_filerevMapping

  # @nodoc
  _writeManifestFile: =>
    @naspi.file.writeJSON @getManifestFile(), @getMapping(), { prettyPrint: true }


