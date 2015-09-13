_         = require 'lodash'
File      = require 'path'

module.exports = class BowerPackageReader

  constructor: (@naspi) ->

  #
  # Resolve as package for the passed bower.json file
  #
  resolve: (bowerPath = null) =>
    bowerPath or= @_baseBowerPath()
    data = @naspi.file.readJSON(bowerPath)
    @_resolveForBowerData(data)

  #
  # Resolve as package for the passed BowerFile instance
  #
  resolveWithBowerData: (data) =>
    @_resolveForBowerData(data)

  #
  # Build a package by the passed package name and version
  #
  buildPackage: (name, version) =>
    if /^\.?\//.test(version)
      @_buildLocalPackage(name, version)
    else
      pkg = new (require('../pkg/bower'))(@naspi, name, version)
      @_registerPackage name, pkg



  # ----------------------------------------------------------
  # private

  # @nodoc
  _baseBowerPath: =>
    File.join(process.cwd(), 'bower.json')

  # @nodoc
  _registerPackage: (name, pkg) =>
    @naspi.pkgs or= {}
    @naspi.pkgs[name] = pkg

  # @nodoc
  _buildLocalPackage: (name, version) =>
    data        = @naspi.file.readJSON(File.join(version, 'bower.json'))
    naspiConfig = data.naspi || {}
    type        = naspiConfig.type || 'simple'
    requirePath = null

    @naspi.verbose.write "Pkg \"#{name}\" - create instance ... "

    _.each @naspi.option('pkgClassPaths'), (path) =>
      return unless @naspi.file.isFile(File.join(path, "#{type}.coffee"))
      requirePath = File.join(path, type)

    if @naspi.file.exists("#{requirePath}.coffee")
      pkg = new (require(requirePath))(@naspi, name, version, data)
      @_registerPackage name, pkg

      @naspi.verbose.writeOk "ok\n"

      @resolveWithBowerData(data)
    else
      @naspi.verbose.writeError "error\n"
      @naspi.verbose.writelnWarn "Package class file \"#{type}\" not found."

    pkg

  # @nodoc
  _resolveForBowerData: (data) =>
    _.each (data.dependencies || {}), (version, name) =>
      @buildPackage(name, version)








