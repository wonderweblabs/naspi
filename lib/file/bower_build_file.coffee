_         = require 'lodash'
path      = require 'path'

module.exports = class BowerBuildFile

  constructor: (@naspi, file = null) ->
    @file = file || @naspi.file

  prepare: ->
    @_setDefaults()

  registerPackage: (name, version) ->
    @getJson().dependencies or= {}
    @getJson().dependencies[name] = version

  getBowerFilePath: ->
    path.join(@naspi.options.buildPath, 'bower.json')

  getJson: ->
    @json or= @file.readJSON(@getBowerFilePath())

  write: ->
    @file.writeJSON(@getBowerFilePath(), @getJson(), { prettyPrint: true })

  _setDefaults: ->
    @getJson().name         or= 'naspi-build'
    @getJson().version      or= '1.0.0'
    @getJson().description  or= ''
    @getJson().dependencies or= {}
    @getJson().private      = true

