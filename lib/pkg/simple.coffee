_             = require 'lodash'
path          = require 'path'
Q             = require 'q'
AbstractBuild = require './abstract_build'

module.exports = class Simple extends AbstractBuild

  onProcess: (options = {}) =>
    deferred = Q.defer()

    Q.fcall(@runTaskCopy, options)
    .then(@runTaskSass, options)
    .then(@runTaskCoffee, options)
    .then(@runTaskHaml, options)
    .done => deferred.resolve()

    deferred.promise

  runTaskCopy: (options = {}) =>
    @getTask('copy').run
      files:  '**/*'
      cwd:    @basePath
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())
      filter: (file) =>
        return false if /bower\.json$/.test(file)
        return false if /\.(coffee|sass|scss|haml)$/.test(file)
        return false unless @naspi.file.isFile(file)
        true

  runTaskSass: (options = {}) =>
    @getTask('sass').run
      files:  '**/*.{sass,scss}'
      cwd:    @basePath
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())

  runTaskCoffee: (options = {}) =>
    @getTask('coffee').run
      files:  '**/*.coffee'
      cwd:    @basePath
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())

  runTaskHaml: (options = {}) =>
    @getTask('haml').run
      files:  '**/*.haml'
      cwd:    @basePath
      dest:   path.join(@naspi.options.buildPath, 'bower_components', @getName())
      options:
        render: true
        hyphenateDataAttrs: true
