_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
gaze      = require 'gaze'
Gaze      = gaze.Gaze
PkgRunChain = require './pkg_run_chain'

module.exports = class PackageRunner

  constructor: (@naspi) ->

  getRunner: =>
    @naspi.pkgRunner

  watch: =>
    _.each @naspi.option('runPkgs'), (runPkg) =>
      pkg = @getRunner().getPackage(runPkg.pkg)
      pkg.setEnv({ runPkg: runPkg })

      _.each pkg.getWatchConfigs(), (watchConfig) =>
        @watchConfig runPkg, watchConfig

  watchConfig: (runPkg, watchConfig) =>
    opts    = {}
    runPkgs = watchConfig.runPkgs
    pkg     = @getRunner().getPackage(runPkg.pkg)

    gaze = new Gaze(watchConfig.files, opts)
    gaze.on 'ready', (watcher)    => console.log 'watching', runPkgs
    gaze.on 'added', (filepath)   => @_onWatcherChange(filepath, runPkgs)
    gaze.on 'changed', (filepath) => @_onWatcherChange(filepath, runPkgs)
    gaze.on 'deleted', (filepath) => @_onWatcherChange(filepath, runPkgs)
    gaze.on 'renamed', (newPath, oldPath) => @_onWatcherChange(oldPath, runPkgs)
    gaze.on 'end',                => console.log 'end', runPkgs
    gaze.on 'error', (err)        => console.log 'error', error, runPkgs
    gaze.on 'nomatch',            => console.log 'nomatch', runPkgs

  _onWatcherChange: (filepath, runPkgs) =>
    @_resetPkgs()

    chain = new PkgRunChain(@naspi)
    _.each runPkgs, (runPkg) =>
      chain.addStep => @getRunner().runPkg(runPkg)
    chain.fail (deferred, e) =>
      deferred.reject(e)
      @naspi.logger.throwError(e.message, e)
    chain.process()

  _resetPkgs: =>
    _.each @naspi.pkgs, (pkg) =>
      pkg.prepared = false
      pkg.preparing = false
      pkg.prepareDeferred = null
      pkg.processed = false
      pkg.processing = false
      pkg.processDeferred = null
      pkg.postProcessed = false
      pkg.postProcessing = false
      pkg.postProcessDeferred = null
