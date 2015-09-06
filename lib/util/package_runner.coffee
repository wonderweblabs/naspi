_         = require 'lodash'
path      = require 'path'
Q         = require 'q'

module.exports = class PackageRunner

  constructor: (@naspi) ->

  run: =>
    @naspi.file.bowerBuildFile.prepare()

    _.each @naspi.options.runPkgs, (runPkg) => @runPkg(runPkg)

  runPkg: (runPkg) =>
    pkg = @getPackage(runPkg.pkg)

    if _.isNull(pkg) || _.isUndefined(pkg)
      msg = "Could not run package \"#{runPkg.pkg}\""
      @naspi.logger.throwError(msg, new Error(msg))

    Q.fcall(pkg.prepare)              # 1. pkg prepare
    .then(@_writeBowerFile, runPkg)   # 2. write bower.json
    .then(@_bowerUpdate, runPkg)      # 3. bower update
    .then(pkg.process)                # 4. pkgs process
    .then(pkg.postProcess)            # 5. pkgs post process
    .done()

  getPackage: (name) =>
    @naspi.pkgs[name]

  _writeBowerFile: (runPkg) =>
    @naspi.file.bowerBuildFile.write()
    Q()

  _bowerUpdate: (runPkg) =>
    deferred = Q.defer()

    @naspi.exec.exec 'bower', ['update'], { cwd: @naspi.options.buildPath }, =>
      deferred.resolve()

    deferred.promise
