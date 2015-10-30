_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

###

###
module.exports = class FilerevCssReplace extends Abstract

  onRun: (deferred, fileMappingList, options = {}, env) =>
    options       = _.defaults (options || {}), @getDefaultOptions()
    fileMappings  = fileMappingList.resolve()

    @_execFiles(fileMappings, options, env)
    deferred.resolve()

  getDefaultOptions: =>
    mappingSubFolder: ''

  getMatchRegex: =>
    /(?:url\([\"\']?)(?!http[s]?)([^\"\'\(\)]*)(?:[\"\']?\))/g

  getManifest: =>
    @_manifest or= @_readManifest()

  getManifestFile: =>
    @naspi.option('manifestFile')

  getAssetHost: (env) =>
    @naspi.option('assetHost', env)


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _execFiles: (fileMappings, options, env) =>
    _.each fileMappings, (fileMapping) => @_replace(fileMapping, options, env)

  # @nodoc
  _replace: (fileMapping, options, env) =>
    src       = fileMapping.src().absolutePath()
    output    = fileMapping.dest().absolutePath()
    content   = @naspi.file.read(src)

    _.each content.match(@getMatchRegex()), (matchStr) =>
      url = matchStr.replace(/url\([\"\']?\/?/g, '')
      url = url.replace(/[\"\']?\)/g, '')
      url = path.join(options.mappingSubFolder, url.split(/[?#]/g)[0])

      url = @getManifest()[url]
      return unless _.isString(url) && !_.isEmpty(url)

      resultUrl = []
      host  = ''
      host  = @getAssetHost(env.runPkg.env) if _.isString(@getAssetHost(env.runPkg.env))
      host  = host.replace(/\/$/, '')
      url   = url.replace(/^\//, '')
      resultUrl.push host
      resultUrl.push url

      content = content.replace(matchStr, "url(\"#{resultUrl.join('/')}\")")

    @naspi.file.write output, content


  # @nodoc
  _readManifest: =>
    return {} unless @naspi.file.exists(@getManifestFile())

    try
      @_manifest = @naspi.file.readJSON(@getManifestFile())
    catch e
      @_manifest = {}

    @_manifest or= {}
    @_manifest

