_     = require 'lodash'
path  = require 'path'

module.exports = class Options

  environment: 'development'

  environments: ['development', 'production']

  runPkgs: []

  # --------------------------------------------------
  # conf keys

  options:
    defaults:

      debug: false

      verbose: false

      watch: false

      notify: false

      maxProcesses: 2

      defaultTask: 'build'

      configFile: './config/naspi.yml'

      userConfigFile: './.naspi.yml'

      # tmp folder for modules
      tmpPath: 'tmp/naspi'

      sassCache: 'tmp/naspi/.sass-cache'

      sassLoadPaths: []

      # naspi tasks cache file
      cacheFile: 'tmp/naspi/.files.json'

      # naspi tasks built track file
      pkgBuiltTrackFile: 'tmp/naspi/.packages.json'

      filerevFile: 'tmp/naspi/.filerev.json'

      manifestSrcCwd: 'naspi_build'
      manifestDestCwd: 'naspi_build'

      manifestFile: 'tmp/naspi/.manifest.json'

      # naspi creates a custom bower folder to bundle all packages
      buildPath: 'naspi_build'

      assetHost: null

      pkgClassPaths: [path.join(__dirname, '..', 'pkg')]

      taskClassPaths: [path.join(__dirname, '..', 'task')]

  # conf keys
  # --------------------------------------------------


  constructor: (@naspi) ->
    @_parseProcessArguments()

  load: =>
    @runPkgs = []
    @options.defaults.pkgClassPaths  = [path.join(__dirname, '..', 'pkg')]
    @options.defaults.taskClassPaths = [path.join(__dirname, '..', 'task')]
    @options[@environment]           = _.cloneDeep(@options.defaults)

    @_parseConfigFile()
    @_parseUserConfigFile()
    @_mergeConfigs()
    @_parseProcessArguments()
    @_normalizeRunPkgs()

  option: (key, env = @environment) =>
    switch key
      when 'runPkgs' then @runPkgs
      when 'environment' then @environment
      when 'environments' then @environments
      else _.result(@options[env], key)

  # ----------------------------------------------------------
  # private

  # @nodoc
  _parseProcessArguments: =>
    _.each (process.argv.slice(2) || []), (a) => @_parseProcessArgument(a)

  # @nodoc
  _parseProcessArgument: (argument) =>
    if /^\-\-/.test(argument)
      opt = argument.replace(/^\-\-/, '').split('=')
      _.each Object.keys(@options), (env_name) =>
        @options[env_name] or= {}
        @options[env_name][opt[0]] = if _.size(opt) > 1 then opt[1] else true
    else
      opt       = argument.split(':')
      opts      = { pkg: opt[0] }
      opts.task = if _.size(opt) > 1 then opt[1] else null
      opts.env  = if _.size(opt) > 2 then opt[2] else null

      @runPkgs.push opts

  # @nodoc
  _parseConfigFile: =>
    return unless @naspi.file.exists(@option('configFile'))

    @_parseYaml(@option('configFile'))

  # @nodoc
  _parseUserConfigFile: =>
    return unless @naspi.file.exists(@option('userConfigFile'))

    @_parseYaml(@option('userConfigFile'))

  # @nodoc
  _parseYaml: (file) =>
    yaml = @naspi.file.readYAML(@option('configFile')) || {}

    _.each yaml, (env, env_name) =>
      @options[env_name] or= {}
      @_mergeConfigData(env_name, env)

  # @nodoc
  _mergeConfigData: (env_name, data) =>
    _.each data, (value, key) =>
      switch key
        when 'pkgClassPaths'
          value = [value] unless _.isArray(value)
          _.each (value || []), (v) =>
            @options[env_name].pkgClassPaths or= []
            @options[env_name].pkgClassPaths.push(path.join(process.cwd(), v))
        when 'taskClassPaths'
          value = [value] unless _.isArray(value)
          _.each (value || []), (v) =>
            @options[env_name].taskClassPaths or= []
            @options[env_name].taskClassPaths.push(path.join(process.cwd(), v))
        when 'sassLoadPaths'
          value = [value] unless _.isArray(value)
          _.each (value || []), (v) =>
            @options[env_name].sassLoadPaths or= []
            @options[env_name].sassLoadPaths.push(path.join(process.cwd(), v))
        else
          @options[env_name][key] = value

  # @nodoc
  _mergeConfigs: =>
    @environments = Object.keys(@options)

    options = {}

    _.each @environments, (env_name) =>
      return if env_name == 'defaults'
      options[env_name] = _.cloneDeep @options.defaults

    _.each @environments, (env_name) =>
      return if env_name == 'defaults'

      _.each @options[env_name], (value, key) =>
        switch key
          when 'pkgClassPaths'
            value = [value] unless _.isArray(value)
            _.each (value || []), (v) =>
              options[env_name].pkgClassPaths or= []
              options[env_name].pkgClassPaths.push(v)
          when 'taskClassPaths'
            value = [value] unless _.isArray(value)
            _.each (value || []), (v) =>
              options[env_name].taskClassPaths or= []
              options[env_name].taskClassPaths.push(v)
          when 'sassLoadPaths'
            value = [value] unless _.isArray(value)
            _.each (value || []), (v) =>
              options[env_name].sassLoadPaths or= []
              options[env_name].sassLoadPaths.push(v)
          else
            options[env_name][key] = value

    @options = options

  # @nodoc
  _normalizeRunPkgs: ->
    _.each @runPkgs, (runPkg) =>
      if !_.isString(runPkg.pkg)
        console.log 'Missing package'
        @naspi.exit(129)

      oriEnv  = runPkg.env
      oriTask = runPkg.task
      env     = runPkg.env
      task    = runPkg.task

      if !_.contains(@option('environments'), env) && _.contains(@option('environments'), task)
        env = task

      if _.contains(@option('environments'), task)
        task = if _.contains(@option('environments'), runPkg.env) then @option('defaultTask') else runPkg.env

      runPkg.env  = env || @environment
      runPkg.task = task || @option('defaultTask')




