_             = require 'lodash'
path          = require 'path'
Q             = require 'q'
AbstractBuild = require './abstract_build'

module.exports = class Simple extends AbstractBuild

  onProcess: =>
    chain = @buildRunChain()
    chain.addStep @runTaskCopy
    chain.addStep @runTaskSass
    chain.addStep @runTaskCoffee
    chain.addStep @runTaskHaml
    chain.process() # returns promise

  runTaskCopy: =>
    @runTask 'copy', @_taskCopyFilesConfig()

  runTaskSass: =>
    @runTask 'sass', @_taskSassFilesConfig(),
      loadPaths: (@naspi.option('sassLoadPaths') || [])
      sourcemap: 'none'

  runTaskCoffee: =>
    @runTask 'coffee', @_taskCoffeeFilesConfig(),
      sourcemap: false

  runTaskHaml: =>
    @runTask 'haml', @_taskHamlFilesConfig(),
      render: true
      hyphenateDataAttrs: true

  getDestPath: =>
    path.join(@naspi.option('buildPath'), 'bower_components', @getName())


  # ----------------------------------------------------------
  # private - files

  # @nodoc
  _taskCopyFilesConfig: =>
    expand:     true
    src:        '**/*'
    cwd:        @basePath
    dest:       @getDestPath()
    eachFilter: @_taskCopyEachFilter

  # @nodoc
  _taskSassFilesConfig: =>
    expand:     true
    src:        '**/*.{sass,scss}'
    cwd:        @basePath
    dest:       @getDestPath()
    ext:        'css'
    eachFilter: @_taskSassEachFilter

  # @nodoc
  _taskCoffeeFilesConfig: =>
    expand:     true
    src:        '**/*.coffee'
    cwd:        @basePath
    dest:       @getDestPath()
    ext:        'js'
    eachFilter: @_taskCoffeeEachFilter

  # @nodoc
  _taskHamlFilesConfig: =>
    expand:     true
    src:        '**/*.haml'
    cwd:        @basePath
    dest:       @getDestPath()
    ext:        'html'
    eachFilter: @_taskHamlEachFilter


  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _taskCopyEachFilter: (fileMapping) =>
    return false if /bower\.json$/.test(fileMapping.src().path())
    return false if /\.(coffee|sass|scss|haml)$/.test(fileMapping.src().path())
    return false if !fileMapping.src().isFile()

    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("simple-copy-#{@getName()}")
      fileMapping.src().updateChangedState("simple-copy-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskSassEachFilter: (fileMapping) =>
    if /^_/.test(fileMapping.src().basename()) then false else true
    # return false if /^_/.test(fileMapping.src().basename())

    # if !fileMapping.dest().exists() || fileMapping.src().hasChanged("simple-sass-#{@getName()}")
    #   fileMapping.src().updateChangedState("simple-sass-#{@getName()}")
    #   true
    # else
    #   false

  # @nodoc
  _taskCoffeeEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("simple-coffee-#{@getName()}")
      fileMapping.src().updateChangedState("simple-coffee-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskHamlEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("simple-haml-#{@getName()}")
      fileMapping.src().updateChangedState("simple-haml-#{@getName()}")
      true
    else
      false


