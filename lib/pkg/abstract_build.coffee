_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'
FileMappingList = require '../file/file_mapping_list'

module.exports = class AbstractBuild extends Abstract

  basePath: null

  config: {}

  constructor: (naspi, name, version, @data) ->
    super(naspi, name, version)

    @basePath = @version
    @config   = @data.naspi || {}

  onPrepare: (env) =>
    chain = @buildRunChain(env)
    chain.addStep @registerForBuild
    chain.addStep @copyBowerFile
    chain.process() # returns promise

  runTask: (env, taskName, fileMappingListConfig, options = {}) =>
    @getTask(taskName).run(
      env,
      new FileMappingList(@naspi, fileMappingListConfig),
      options
    )

  getTask: (taskName) ->
    try
      TaskName = @getTaskClass(taskName)
      new TaskName(@naspi, @)
    catch e
      @naspi.logger.throwError(e.message, e)
      TaskName = @getTaskClass('reject')
      new TaskName(@naspi, @, e)

  getTaskClass: (taskName) ->
    requirePath = null

    _.each @naspi.option('taskClassPaths'), (file) =>
      return unless @naspi.file.isFile(path.join(file, "#{taskName}.coffee"))
      requirePath = path.join(file, taskName)

    unless _.isString(requirePath)
      throw new Error("Could not find any file for task #{taskName}")

    require(requirePath)

  getDependencyPackages: =>
    _.map (@data.dependencies || {}), (version, name) => @naspi.pkgs[name]

  registerForBuild: =>
    folder = path.join('bower_components', @getName())
    @naspi.file.bowerBuildFile.registerPackage(@getName(), "./#{folder}")
    Q.resolve()

  copyBowerFile: =>
    pkgBowerFile  = path.join('./', @basePath, 'bower.json')
    bowerData     = @naspi.file.readJSON(pkgBowerFile)

    _.each (bowerData.dependencies || []), (version, name) =>
      return unless /^\.?\//.test(version)
      newVersion = path.join('bower_components', name)
      bowerData.dependencies[name] = "./#{newVersion}"

    resultBowerPath = path.join('./', @naspi.option('buildPath'), 'bower_components', @getName())
    resultBowerFile = path.join('./', resultBowerPath, 'bower.json')
    @naspi.file.mkdir(resultBowerPath)
    @naspi.file.writeJSON(resultBowerFile, bowerData, { prettyPrint: true })

    Q.resolve()