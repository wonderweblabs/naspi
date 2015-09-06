_     = require 'lodash'
path  = require 'path'

module.exports = class Options

  debug: false

  verbose: false

  defaultTask: 'build'

  environment: 'development'

  environments: ['development', 'production']

  configFile: './config/naspi.yml'

  userConfigFile: './.naspi.yml'

  runPkgs: []

  # tmp folder for modules
  tmpPath: 'tmp/naspi'

  sassCache: 'tmp/naspi/.sass-cache'

  # naspi tasks cache file
  cacheFile: 'tmp/naspi/.files.json'

  # naspi tasks built track file
  pkgBuiltTrackFile: 'tmp/naspi/.packages.json'

  # naspi creates a custom bower folder to bundle all packages
  buildPath: 'naspi_build'

  pkgClassPaths: [path.join(__dirname, '..', 'pkg')]

  taskClassPaths: [path.join(__dirname, '..', 'task')]


  constructor: (@naspi) ->
    @_parseProcessArguments()

  load: =>
    @runPkgs        = []
    @pkgClassPaths  = [path.join(__dirname, '..', 'pkg')]
    @taskClassPaths = [path.join(__dirname, '..', 'task')]

    @_parseConfigFile()
    @_parseUserConfigFile()
    @_parseProcessArguments()
    @_normalizeRunPkgs()

  # ----------------------------------------------------------
  # private

  # @nodoc
  _parseProcessArguments: =>
    _.each (process.argv.slice(2) || []), (a) => @_parseProcessArgument(a)

  # @nodoc
  _parseProcessArgument: (argument) =>
    if /^\-\-/.test(argument)
      opt = argument.replace(/^\-\-/, '').split('=')
      @[opt[0]] = if _.size(opt) > 1 then opt[1] else true
    else
      opt       = argument.split(':')
      opts      = { pkg: opt[0] }
      opts.task = if _.size(opt) > 1 then opt[1] else null
      opts.env  = if _.size(opt) > 2 then opt[2] else null

      @runPkgs.push opts

  # @nodoc
  _parseConfigFile: =>
    return unless @naspi.file.exists(@configFile)

    @_mergeConfigData((@naspi.file.readYAML(@configFile) || {})[@environment])

  # @nodoc
  _parseUserConfigFile: =>
    return unless @naspi.file.exists(@userConfigFile)

    @_mergeConfigData((@naspi.file.readYAML(@userConfigFile) || {})[@environment])

  # @nodoc
  _mergeConfigData: (data) =>
    _.each data, (value, key) =>
      switch key
        when 'pkgClassPaths'
          value = [value] unless _.isArray(value)
          _.each (value || []), (v) => @pkgClassPaths.push(path.join(process.cwd(), v))
        when 'taskClassPaths'
          value = [value] unless _.isArray(value)
          _.each (value || []), (v) => @taskClassPaths.push(path.join(process.cwd(), v))
        else @[key] = value

  # @nodoc
  _normalizeRunPkgs: ->
    _.each @runPkgs, (runPkg) =>
      if !_.isString(runPkg.pkg)
        console.log 'Missing package'
        @naspi.exit(129)

      oriEnv  = runPkg.env
      oriTask = runPkg.task
      env     = null
      task    = null

      if _.contains(@environments, runPkg.task) && !_.contains(@environments, runPkg.env)
        env = runPkg.task
      else if _.contains(@environments, runPkg.env)
        env = runPkg.env

      if !_.contains(@environments, runPkg.task) && _.contains(@environments, runPkg.env)
        task = runPkg.env
      else if !_.contains(@environments, runPkg.task)
        task = runPkg.task

      runPkg.env  = env || @environment
      runPkg.task = task || @defaultTask





