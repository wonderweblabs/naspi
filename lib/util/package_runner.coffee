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

    env = { runPkg: runPkg }

    pkg.prepare(env)                # 1. pkg prepare
    .then(@_writeBowerFile)         # 2. write bower.json
    .then(@_bowerUpdate)            # 3. bower update
    .then(pkg.process)              # 4. pkgs process
    .then(pkg.postProcess)          # 5. pkgs post process
    .then(@_writeFileChangeTracker) # 6. write files cache
    .fail (e) => @naspi.logger.throwError(e.message, e)

  getPackage: (name) =>
    @naspi.pkgs[name]

  _writeBowerFile: (env) =>
    @naspi.file.bowerBuildFile.write()
    Q.resolve(env)

  _bowerUpdate: (env) =>
    deferred = Q.defer()

    bowerFiles = @naspi.file.expand({
      cwd: @naspi.options.buildPath
      filter: 'isFile'
    }, path.join(@naspi.options.buildPath), '**/bower.json')

    changedBowerFiles = false

    _.each bowerFiles, (file) =>
      return if changedBowerFiles == true
      changedBowerFiles = @naspi.file.changeTracker.hasChanged(file, "naspi-bower-update")

    if changedBowerFiles == true
      @naspi.exec.exec deferred, 'bower', ['update'], { cwd: @naspi.options.buildPath }
      _.each bowerFiles, (file) => @naspi.file.changeTracker.update(file, "naspi-bower-update")
    else
      deferred.resolve(env)

    deferred.promise

  _writeFileChangeTracker: (env) =>
    deferred = Q.defer()
    @naspi.file.changeTracker.persist()
    deferred.resolve(env)
    deferred.promise

