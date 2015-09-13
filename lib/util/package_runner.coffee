_         = require 'lodash'
path      = require 'path'
Q         = require 'q'

module.exports = class PackageRunner

  constructor: (@naspi) ->

  run: =>
    @naspi.file.bowerBuildFile.prepare()

    _.each @naspi.option('runPkgs'), (runPkg) => @runPkg(runPkg)

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
    Q(env)

  _bowerUpdate: (env) =>
    deferred = Q.defer()

    bowerFiles = @naspi.file.expand({
      cwd: @naspi.option('buildPath')
      filter: 'isFile'
    }, path.join(@naspi.option('buildPath')), '**/bower.json')

    changedBowerFiles = false

    _.each bowerFiles, (file) =>
      file = path.join(@naspi.option('buildPath'), file)
      if @naspi.file.changeTracker.hasChanged(file, "naspi-bower-update")
        changedBowerFiles = true
        @naspi.file.delete path.join(path.dirname(file), '.bower.json'), { force: true }

    if changedBowerFiles == true
      @naspi.exec.exec deferred, 'bower', ['update'], { cwd: @naspi.option('buildPath') }
      _.each bowerFiles, (file) =>
        file = path.join(@naspi.option('buildPath'), file)
        @naspi.file.changeTracker.update(file, "naspi-bower-update")
    else
      deferred.resolve(env)

    deferred.promise

  _writeFileChangeTracker: (env) =>
    deferred = Q.defer()
    @naspi.file.changeTracker.persist()
    deferred.resolve(env)
    deferred.promise

