_             = require 'lodash'
path          = require 'path'
Q             = require 'q'
AbstractBuild = require '../../lib/pkg/abstract_build'

module.exports = class PkgCustomApplication extends AbstractBuild

  onProcess: (options = {}) =>
    deferred = Q.defer()

    Q.fcall(@runTaskCopyImages, options)
    .then(@runTaskSassCompile, options)
    .then(@runTaskCoffee, options)
    .then(@runTaskHaml, options)
    .done => deferred.resolve()

    deferred.promise

  onPostProcess: (options = {}) =>
    deferred = Q.defer()

    Q.fcall(@runPostTaskCopy, options)
    .then(@runPostTaskConcatJs, options)
    .then(@runPostTaskConcatCss, options)
    .then(@runPostTaskConcatTemplates, options)
    .done => deferred.resolve()

    deferred.resolve()

    deferred.promise

  runTaskCopyImages: (options = {}) =>
    @getTask('copy').run
      files:  'images/**/*'
      cwd:    @basePath
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())

  runTaskSassCompile: (options = {}) =>
    @getTask('sass').run
      files:  'stylesheets/application.sass'
      cwd:    @basePath
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())
      options:
        loadPaths: [
          path.join(@basePath, 'stylesheets'),
          path.join(@basePath, '../application-external'),
          path.join(@naspi.options.buildPath, 'bower_components', 'bourbon/app/assets/stylesheets'),
        ]
        sourcemap: 'none'

  runTaskCoffee: (options = {}) =>
    @getTask('coffee').run
      files:  '**/*.coffee'
      cwd:    path.join(@basePath, 'javascripts')
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName(), 'javascripts')

  runTaskHaml: (options = {}) =>
    @getTask('haml').run
      files:  '**/*.haml'
      cwd:    path.join(@basePath, 'templates')
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName(), 'templates')
      options:
        render: true
        hyphenateDataAttrs: true

  runPostTaskCopy: (options = {}) =>
    @getTask('copy').run
      files:  '**/*'
      cwd:    path.join(@naspi.options.buildPath, 'bower_components', @getName(), 'images')
      dest:   path.join('tmp', 'dummy', 'application')
      filter: (file) =>
        return false if /bower\.json$/.test(file)
        return false if /\.(coffee|sass|scss|haml|js|js\.map|css|css\.map|html)$/.test(file)
        return false unless @naspi.file.isFile(file)
        true
    @getTask('copy').run
      files:  '**/*'
      cwd:    path.join(@naspi.options.buildPath, 'bower_components', 'css-social-buttons', 'css')
      dest:   path.join('tmp', 'dummy', 'application')
      filter: (file) =>
        return false if /\.(css)$/.test(file)
        return false unless @naspi.file.isFile(file)
        true

  runPostTaskConcatJs: (options = {}) =>
    @getTask('source_map').run
      files: [
        'requirejs/require.js',
        'jquery/dist/jquery.js',
        'application/javascripts/**/*.js'
      ]
      cwd:      path.join(@naspi.options.buildPath, 'bower_components')
      destFile: path.join('tmp', 'dummy', 'application', 'application.js')

  runPostTaskConcatCss: (options = {}) =>
    @getTask('concat').run
      files: [
        'css-social-buttons/css/zocial.css',
        'application/stylesheets/application.css'
      ]
      cwd:      path.join(@naspi.options.buildPath, 'bower_components')
      destFile: path.join('tmp', 'dummy', 'application', 'application.css')

  runPostTaskConcatTemplates: (options = {}) =>
    @getTask('concat').run
      files: [
        'application/templates/**/*.html'
      ]
      cwd:      path.join(@naspi.options.buildPath, 'bower_components')
      destFile: path.join('tmp', 'dummy', 'application', 'templates.html')



