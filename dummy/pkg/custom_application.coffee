_             = require 'lodash'
path          = require 'path'
Q             = require 'q'
AbstractBuild = require '../../lib/pkg/abstract_build'

module.exports = class PkgCustomApplication extends AbstractBuild

  onProcess: (env) =>
    chain = @buildRunChain(env)
    chain.addStep @runTaskCopyImages
    chain.addStep @runTaskSassCompile
    chain.addStep @runTaskCoffee
    chain.addStep @runTaskHaml
    chain.process() # returns promise

  onPostProcess: (env) =>
    chain = @buildRunChain(env)
    chain.addStep @runPostTaskCopy
    chain.addStep @runPostTaskConcatJs
    chain.addStep @runPostTaskConcatCss
    chain.addStep @runPostTaskConcatTemplates
    chain.process() # returns promise

  runTaskCopyImages: (env) =>
    @runTask 'copy', @_taskCopyFilesImagesConfig()

  runTaskSassCompile: (env) =>
    @runTask 'sass', @_taskSassCompileConfig(),
      loadPaths: [
        path.join(@basePath, 'stylesheets'),
        path.join(@basePath, '../application-external'),
        path.join(@naspi.options.buildPath, 'bower_components', 'bourbon/app/assets/stylesheets')
      ]
      sourcemap: 'none'

  runTaskCoffee: (env) =>
    @runTask 'coffee', @_taskCoffeeConfig()

  runTaskHaml: (env) =>
    @runTask 'haml', @_taskHamlConfig(),
      render: true
      hyphenateDataAttrs: true

  runPostTaskCopy: (env) =>
    @runTask 'copy', @_taskPostCopyImgConfig()
    @runTask 'copy', @_taskPostCopyCSBConfig()

  runPostTaskConcatJs: (env) =>
    @runTask 'source_map', @_taskPostConcatJsConfig()

  runPostTaskConcatCss: (env) =>
    @runTask 'concat', @_taskPostConcatCssConfig()

  runPostTaskConcatTemplates: (env) =>
    @runTask 'concat', @_taskPostConcatTplConfig()


  # ----------------------------------------------------------
  # private - files

  # @nodoc
  _taskCopyFilesImagesConfig: =>
    expand: true
    src:   'images/**/*'
    cwd:    @basePath
    dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())
    eachFilter: @_taskCopyImagesEachFilter

  # @nodoc
  _taskSassCompileConfig: =>
    expand: true
    src:  'stylesheets/application.sass'
    cwd:  @basePath
    dest: path.join(@naspi.options.buildPath, 'bower_components', @getName())
    ext:  'css'
    eachFilter: @_taskSassCompileEachFilter

  # @nodoc
  _taskCoffeeConfig: =>
    expand: true
    src:  '**/*.coffee'
    cwd:  path.join(@basePath, 'javascripts')
    dest: path.join(@naspi.options.buildPath, 'bower_components', @getName(), 'javascripts')
    ext:  'js'
    eachFilter: @_taskCoffeeEachFilter

  # @nodoc
  _taskHamlConfig: =>
    expand: true
    src:  '**/*.haml'
    cwd:  path.join(@basePath, 'templates')
    dest: path.join(@naspi.options.buildPath, 'bower_components', @getName(), 'templates')
    ext:  'html'
    eachFilter: @_taskHamlEachFilter

  # @nodoc
  _taskPostCopyImgConfig: =>
    expand: true
    src:  '**/*'
    cwd:  path.join(@naspi.options.buildPath, 'bower_components', @getName(), 'images')
    dest: path.join('tmp', 'dummy', 'application')
    eachFilter: @_taskPostCopyImgEachFilter

  # @nodoc
  _taskPostCopyCSBConfig: =>
    expand: true
    src:  '**/*'
    cwd:  path.join(@naspi.options.buildPath, 'bower_components', 'css-social-buttons', 'css')
    dest: path.join('tmp', 'dummy', 'application')
    eachFilter: @_taskPostCopyCSBEachFilter

  # @nodoc
  _taskPostConcatJsConfig: =>
      src: [
        'requirejs/require.js',
        'jquery/dist/jquery.js',
        'application/javascripts/**/*.js'
      ]
      cwd:  path.join(@naspi.options.buildPath, 'bower_components')
      dest: path.join('tmp', 'dummy', 'application', 'application.js')
      eachFilter: @_taskPostConcatJsEachFilter

  # @nodoc
  _taskPostConcatCssConfig: =>
    src: [
      'css-social-buttons/css/zocial.css',
      'application/stylesheets/application.css'
    ]
    cwd:  path.join(@naspi.options.buildPath, 'bower_components')
    dest: path.join('tmp', 'dummy', 'application', 'application.css')
    eachFilter: @_taskPostConcatCssEachFilter

  # @nodoc
  _taskPostConcatTplConfig: =>
    src: [
      'application/templates/**/*.html'
    ]
    cwd:  path.join(@naspi.options.buildPath, 'bower_components')
    dest: path.join('tmp', 'dummy', 'application', 'templates.html')
    eachFilter: @_taskPostConcatTplEachFilter



  # ----------------------------------------------------------
  # private - filter

  # @nodoc
  _taskCopyImagesEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-cpi-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-cpi-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskSassCompileEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-sass-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-sass-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskCoffeeEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-coffee-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-coffee-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskHamlEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-haml-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-haml-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskPostCopyImgEachFilter: (fileMapping) =>
    return false if /bower\.json$/.test(fileMapping.src().path())
    return false if /\.(coffee|sass|scss|haml|js|js\.map|css|css\.map|html)$/.test(fileMapping.src().path())
    return false unless @naspi.file.isFile(fileMapping.src().pathFromRoot())

    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-copy-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-copy-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskPostCopyCSBEachFilter: (fileMapping) =>
    return false if /\.(css)$/.test(fileMapping.src().path())
    return false unless @naspi.file.isFile(fileMapping.src().pathFromRoot())

    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-copy-csb-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-copy-csb-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskPostConcatJsEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-concat-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-concat-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskPostConcatCssEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-concat-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-concat-#{@getName()}")
      true
    else
      false

  # @nodoc
  _taskPostConcatTplEachFilter: (fileMapping) =>
    if !fileMapping.dest().exists() || fileMapping.src().hasChanged("custom-app-concat-#{@getName()}")
      fileMapping.src().updateChangedState("custom-app-concat-#{@getName()}")
      true
    else
      false


