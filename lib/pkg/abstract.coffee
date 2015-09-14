_           = require 'lodash'
Q           = require 'q'
PkgRunChain = require '../util/pkg_run_chain'

module.exports = class PkgAbstract

  prepared:             false
  preparing:            false
  prepareDeferred:      null

  processed:            false
  processing:           false
  processDeferred:      null

  postProcessed:        false
  postProcessing:       false
  postProcessDeferred:  null

  env: null

  constructor: (@naspi, @name, @version) ->

  buildRunChain: (deferred) =>
    new PkgRunChain(@naspi, deferred)

  setEnv: (env) => @env = env

  prepare: =>
    if @prepared == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already prepared"
      return Q.resolve() # already resolved promise

    if @preparing == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already preparing"
      # return @prepareDeferred.promise
      return Q.resolve() # already resolved promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - prepare ... start"
    @preparing        = true
    @prepareDeferred  or= Q.defer()

    chain = @buildRunChain(@prepareDeferred)
    chain.addStep @prepareDependencies
    chain.addStep @onBeforePrepare
    chain.addStep @onPrepare
    chain.addStep @onAfterPrepare
    chain.done (deferred) =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - prepare ... "
      @naspi.verbose.writeOk "ok\n"
      @prepared = true
      deferred.resolve()
    chain.process() # returns promise

  process: =>
    if @processed == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already processed"
      return Q.resolve() # already resolved promise

    if @processing == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already processing"
      # return @processDeferred.promise
      return Q.resolve() # already resolved promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - process ... start"
    @processing       = true
    @processDeferred  or= Q.defer()

    chain = @buildRunChain(@processDeferred)
    chain.addStep @processDependencies
    chain.addStep @onBeforeProcess
    chain.addStep @onProcess
    chain.addStep @onAfterProcess
    chain.done (deferred) =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - process ... "
      @naspi.verbose.writeOk "ok\n"
      @processed = true
      deferred.resolve()
    chain.process() # returns promise

  postProcess: =>
    if @postProcessed == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already post processed"
      return Q.resolve() # already resolved promise

    if @postProcessing == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already post processing"
      # return @postProcessDeferred.promise
      return Q.resolve() # already resolved promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - post process ... start"
    @postProcessing       = true
    @postProcessDeferred  or= Q.defer()

    chain = @buildRunChain(@postProcessDeferred)
    chain.addStep @postProcessDependencies
    chain.addStep @onBeforePostProcess
    chain.addStep @onPostProcess
    chain.addStep @onAfterPostProcess
    chain.addStep @updateBuildInfo
    chain.done (deferred) =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - post process ... "
      @naspi.verbose.writeOk "ok\n"
      @postProcessed = true
      deferred.resolve()
    chain.process() # returns promise

  onBeforePrepare:      => Q.resolve() # already resolved promise

  onPrepare:            => Q.resolve() # already resolved promise

  onAfterPrepare:       => Q.resolve() # already resolved promise

  onBeforeProcess:      => Q.resolve() # already resolved promise

  onProcess: =>
    @naspi.verbose.writelnWarn "Pkg \"#{@name}\" - nothing to process"
    Q.resolve() # already resolved promise

  onAfterProcess:       => Q.resolve() # already resolved promise

  onBeforePostProcess:  => Q.resolve() # already resolved promise

  onPostProcess:        => Q.resolve() # already resolved promise

  onAfterPostProcess:   => Q.resolve() # already resolved promise

  getName: =>
    @name

  getVersion: =>
    @version

  getDependencyPackages: =>
    []

  getWatchConfigs: =>
    []

  prepareDependencies: =>
    chain = @buildRunChain()
    _.map @getDependencyPackages(), (pkg) =>
      return if !_.contains(Object.keys(@naspi.pkgs), pkg.getName())
      pkg.setEnv @env
      chain.addStep pkg.prepare
    chain.done (deferred) => deferred.resolve()
    chain.process() # returns promise

  processDependencies: =>
    chain = @buildRunChain()
    _.map @getDependencyPackages(), (pkg) =>
      return if !_.contains(Object.keys(@naspi.pkgs), pkg.getName())
      pkg.setEnv @env
      chain.addStep pkg.process
    chain.done (deferred) => deferred.resolve()
    chain.process() # returns promise

  postProcessDependencies: =>
    chain = @buildRunChain()
    _.map @getDependencyPackages(), (pkg) =>
      return if !_.contains(Object.keys(@naspi.pkgs), pkg.getName())
      pkg.setEnv @env
      chain.addStep pkg.postProcess
    chain.done (deferred) => deferred.resolve()
    chain.process() # returns promise

  updateBuildInfo: =>
    # todo
    Q.resolve()

  _failPromise: (deferred, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)


