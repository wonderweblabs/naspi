_           = require 'lodash'
Q           = require 'q'
PkgRunChain = require('../util/pkg_run_chain')

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

  constructor: (@naspi, @name, @version) ->

  buildRunChain: (env, deferred) =>
    new PkgRunChain(@naspi, env, deferred)

  prepare: (env) =>
    if @prepared == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already prepared"
      return Q(env) # already resolved promise

    if @preparing == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already preparing"
      return @prepareDeferred.promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - prepare ... start"
    @preparing        = true
    @prepareDeferred  or= Q.defer()

    chain = @buildRunChain(env, @prepareDeferred)
    chain.addStep @prepareDependencies
    chain.addStep @onBeforePrepare
    chain.addStep @onPrepare
    chain.addStep @onAfterPrepare
    chain.done (deferred, env) =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - prepare ... "
      @naspi.verbose.writeOk "ok\n"
      @prepared = true
      deferred.resolve(env)
    chain.process() # returns promise

  process: (env) =>
    if @processed == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already processed"
      return Q(env) # already resolved promise

    if @processing == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already processing"
      return @processDeferred.promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - process ... start"
    @processing       = true
    @processDeferred  or= Q.defer()

    chain = @buildRunChain(env, @processDeferred)
    chain.addStep @processDependencies
    chain.addStep @onBeforeProcess
    chain.addStep @onProcess
    chain.addStep @onAfterProcess
    chain.done (deferred, env) =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - process ... "
      @naspi.verbose.writeOk "ok\n"
      @processed = true
      deferred.resolve(env)
    chain.process() # returns promise

  postProcess: (env) =>
    if @postProcessed == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already post processed"
      return Q(env) # already resolved promise

    if @postProcessing == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already post processing"
      return @postProcessDeferred.promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - post process ... start"
    @postProcessing       = true
    @postProcessDeferred  or= Q.defer()

    chain = @buildRunChain(env, @postProcessDeferred)
    chain.addStep @postProcessDependencies
    chain.addStep @onBeforePostProcess
    chain.addStep @onPostProcess
    chain.addStep @onAfterPostProcess
    chain.addStep @updateBuildInfo
    chain.done (deferred, env) =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - post process ... "
      @naspi.verbose.writeOk "ok\n"
      @postProcessed = true
      deferred.resolve(env)
    chain.process() # returns promise

  onBeforePrepare:      (env) => Q(env) # already resolved promise

  onPrepare:            (env) => Q(env) # already resolved promise

  onAfterPrepare:       (env) => Q(env) # already resolved promise

  onBeforeProcess:      (env) => Q(env) # already resolved promise

  onProcess: (env) =>
    @naspi.verbose.writelnWarn "Pkg \"#{@name}\" - nothing to process"
    Q(env) # already resolved promise

  onAfterProcess:       (env) => Q(env) # already resolved promise

  onBeforePostProcess:  (env) => Q(env) # already resolved promise

  onPostProcess:        (env) => Q(env) # already resolved promise

  onAfterPostProcess:   (env) => Q(env) # already resolved promise

  getName: =>
    @name

  getVersion: =>
    @version

  getDependencyPackages: =>
    []

  getWatchConfigs: =>
    []

  prepareDependencies: (env) =>
    chain = @buildRunChain(env)
    _.map @getDependencyPackages(), (pkg) =>
      return if !_.contains(Object.keys(@naspi.pkgs), pkg.getName())
      chain.addStep pkg.prepare
    chain.done (deferred, env) => deferred.resolve(env)
    chain.process() # returns promise

  processDependencies: (env) =>
    chain = @buildRunChain(env)
    _.map @getDependencyPackages(), (pkg) =>
      return if !_.contains(Object.keys(@naspi.pkgs), pkg.getName())
      chain.addStep pkg.process
    chain.done (deferred, env) => deferred.resolve(env)
    chain.process() # returns promise

  postProcessDependencies: (env) =>
    chain = @buildRunChain(env)
    _.map @getDependencyPackages(), (pkg) =>
      return if !_.contains(Object.keys(@naspi.pkgs), pkg.getName())
      chain.addStep pkg.postProcess
    chain.done (deferred, env) => deferred.resolve(env)
    chain.process() # returns promise

  updateBuildInfo: =>
    # todo

  _failPromise: (deferred, error) =>
    deferred.reject(error)
    @naspi.logger.throwError(error.message, error)


