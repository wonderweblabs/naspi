_ = require 'lodash'
Q = require 'q'

module.exports = class PkgAbstract

  prepared:       false
  processed:      false
  postProcessed:  false

  constructor: (@naspi, @name, @version) ->

  prepare: (options = {}) =>
    deferred = Q.defer()

    Q.fcall(@processDependencies, options)
    .then(@_prepare, options)
    .catch((e) => @naspi.logger.throwError(e.message, e))
    .done => deferred.resolve()

    deferred.promise

  _prepare: (options = {}) =>
    if @prepared == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already prepared"
      return Q() # already resolved promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - prepare ... start"

    deferred = Q.defer()

    Q.fcall(@onBeforePrepare, options)
    .then(@onPrepare, options)
    .then(@onAfterPrepare, options)
    .done =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - prepare ... "
      @naspi.verbose.writeOk "ok\n"
      @prepared = true
      deferred.resolve()

    deferred.promise

  process: (options = {}) =>
    if @processed == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already processed"
      return Q() # already resolved promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - process ... start"

    deferred = Q.defer()

    Q.fcall(@onBeforeProcess, options)
    .then(@onProcess, options)
    .then(@onAfterProcess, options)
    .done =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - process ... "
      @naspi.verbose.writeOk "ok\n"
      @processed = true
      deferred.resolve()

    deferred.promise

  postProcess: (options = {}) =>
    if @postProcessed == true
      @naspi.verbose.writeln "Pkg \"#{@getName()}\" - already post processed"
      return Q() # already resolved promise

    @naspi.verbose.writeln "Pkg \"#{@getName()}\" - post process ... start"

    deferred = Q.defer()

    Q.fcall(@onBeforePostProcess, options)
    .then(@onPostProcess, options)
    .then(@onAfterPostProcess, options)
    .then(@updateBuildInfo)
    .done =>
      @naspi.verbose.write "Pkg \"#{@getName()}\" - post process ... "
      @naspi.verbose.writeOk "ok\n"
      @postProcessed = true
      deferred.resolve()

    deferred.promise

  onBeforePrepare:      (options = {}) => Q() # already resolved promise

  onPrepare:            (options = {}) => Q() # already resolved promise

  onAfterPrepare:       (options = {}) => Q() # already resolved promise

  onBeforeProcess:      (options = {}) => Q() # already resolved promise

  onProcess: (options = {}) =>
    @naspi.verbose.writelnWarn "Pkg \"#{@name}\" - nothing to process"
    Q() # already resolved promise

  onAfterProcess:       (options = {}) => Q() # already resolved promise

  onBeforePostProcess:  (options = {}) => Q() # already resolved promise

  onPostProcess:        (options = {}) => Q() # already resolved promise

  onAfterPostProcess:   (options = {}) => Q() # already resolved promise

  getName: =>
    @name

  getVersion: =>
    @version

  getDependencyPackages: =>
    []

  processDependencies: (options) =>
    Q.all _.map(@getDependencyPackages(), (pkg) =>
      return Q() if !_.contains(@naspi.pkgs, pkg.getName())

      deferred = Q.defer()

      Q.fcall(pkg.prepare, options)
      .then(pkg.process, options)
      .then(pkg.postProcess, options)
      .done(=> deferred.resolve())

      deferred.promise
    )

  updateBuildInfo: =>
    # todo


