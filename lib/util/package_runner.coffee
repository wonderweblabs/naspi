_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
notifier  = require 'node-notifier'

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

    pkg.setEnv(env)
    pkg.prepare()                   # 1. pkg prepare
    .then(@_writeBowerFile)         # 2. write bower.json
    .then(@_bowerUpdate)            # 3. bower update
    .then(pkg.process)              # 4. pkgs process
    .then(pkg.postProcess)          # 5. pkgs post process
    .then(@_writeFileChangeTracker) # 6. write files cache
    .then(=> @notifyChanges(env))   # 7. notification
    .fail (e) => @naspi.logger.throwError(e.message, e)

  getPackage: (name) =>
    @naspi.pkgs[name]

  _writeBowerFile: =>
    @naspi.file.bowerBuildFile.write()
    Q.resolve()

  _bowerUpdate: =>
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
      deferred.resolve()

    deferred.promise

  _writeFileChangeTracker: =>
    deferred = Q.defer()
    @naspi.file.changeTracker.persist()
    deferred.resolve()
    deferred.promise

  notifyChanges: (env) =>
    runPkg = env.runPkg
    notifier.notify
      title:    'naspi processed'
      message:  [runPkg.pkg, runPkg.task, runPkg.env].join(':')
      wait: false
    env

