_             = require 'lodash'
path          = require 'path'
Q             = require 'q'

module.exports = class SimpleWebcomponent extends require('./simple')

  copyBowerFile: =>
    pkgBowerFile  = path.join('./', @basePath, 'bower.json')
    bowerData     = @naspi.file.readJSON(pkgBowerFile)

    _.each (bowerData.dependencies || []), (version, name) =>
      return unless /^\.?\//.test(version)
      newVersion = path.join('bower_components', name)
      bowerData.dependencies[name] = "./#{newVersion}"

    resultBowerPath     = path.join('./', @naspi.option('buildPath'), 'bower_components', @getName())
    resultBowerFile     = path.join('./', resultBowerPath, 'bower.json')
    resultBowerDotFile  = path.join('./', resultBowerPath, '.bower.json')
    @naspi.file.mkdir(resultBowerPath)
    @naspi.file.writeJSON(resultBowerFile, bowerData, { prettyPrint: true })
    @naspi.file.writeJSON(resultBowerDotFile, bowerData, { prettyPrint: true })

    Q.resolve()
