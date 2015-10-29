_   = require 'lodash'
Fs  = require 'fs'

#
# Cache entries are based on a scope (key in root json object).
#
# You can pass a defaultScope to the constructor. If not
# 'file_change_tracker' will be the default scope.
#
# When using a function, you can always pass a scope too. If there
# is no scope passed, the defaultScope is used instead.
#
# * cleanAll([scope])                     - clean cache
# * clean(file [, scope])                 - clean file cache
# * hasChanged(file [, scope])            - check for change
# * update(file [, scope])                - update file entry
# * updateMultiple(files [, scope])       - update files entries
# * reloadMapping([scope])                - reload from cache file
# * getMapping([scope])                   - mapping object
# * getTimestamp(file, [, scope])         - cached timestamp
# * getChecksum(file, [, scope])          - cached checksum
# * getData(file, [, scope])              - cached data
# * getFileTimestamp(file, [, scope])     - file timestamp
# * getFileChecksum(file, [, scope])      - file checksum
# * getFileData(file, [, scope])          - file data
#
module.exports = class FileChangeTracker

  _defaultScope: 'file_change_tracker'

  #
  # Init.
  #
  constructor: (@naspi, file = null) ->
    @file = file || @naspi.file
    @_mapping = @_loadMapping()

  #
  getFilePath: ->
    @naspi.option('cacheFile')

  #
  persist: ->
    @_writeCache()

  #
  # Remove all cache entries for scope.
  #
  cleanAll: (scope = @_defaultScope) ->
    @getMapping(scope)
    @setMapping({}, scope)

    @_writeCache()

  #
  # Remove cache entry of file for scope.
  #
  clean: (file, scope = @_defaultScope) ->
    return unless _.isString(file) && file.length > 0

    mapping = @getMapping(scope)
    delete mapping[file]

    @setMapping(mapping, scope)
    @_writeCache()

  #
  # Check file for changes for scope.
  #
  hasChanged: (file, scope = @_defaultScope) ->
    return false unless _.isString(file) && file.length > 0

    @_hasChanged(file, scope)

  #
  # Update cache entry of file for scope.
  #
  # You can pass an array for file to call 'updateMultiple'
  # indirectly.
  #
  update: (file, scope = @_defaultScope) ->
    return @updateMultiple(file, scope) if _.isArray(file)
    return unless _.isString(file) && _.size(file) > 0
    return unless @file.isFile(file)

    @getMapping(scope)[file] = @getFileData(file)

  #
  # Update cache entres of each file in file for scope.
  #
  updateMultiple: (files, scope = @_defaultScope) ->
    return unless _.isArray(files)
    return unless _.size(files) > 0

    mapping = @getMapping(scope)

    _.each files, (file) =>
      mapping[file] = @getFileData(file) if _.isString(file) && file.length > 0

    @setMapping(mapping, scope)

  #
  # Give the mapping object for scope.
  #
  getMapping: (scope = @_defaultScope) ->
    @_mapping         or= {}
    @_mapping[scope]  or= {}

    @_mapping[scope]

  #
  setMapping: (mapping, scope = @_defaultScope) ->
    @_mapping         or= {}
    @_mapping[scope]  or= {}

    @_mapping[scope] = mapping



  #
  # Get cache entry timestamp of file for scope.
  #
  getTimestamp: (file, scope = @_defaultScope) ->
    return 0 unless _.isString(file) && file.length > 0

    @getData(file, scope).mtime || 0

  #
  # Get cache entry checksum of file for scope.
  #
  getChecksum: (file, scope = @_defaultScope) ->
    return null unless _.isString(file) && file.length > 0

    @getData(file, scope).checksum || null

  #
  # Get cache entry timestamp/checksum of file for scope.
  #
  getData: (file, scope = @_defaultScope) ->
    return null unless _.isString(file) && file.length > 0

    @getMapping(scope)[file] || {}


  #
  # Get file timestamp of file for scope.
  #
  getFileTimestamp: (file) ->
    return 0 unless _.isString(file) && file.length > 0
    return 0 unless @file.exists(file)

    @getFileData(file).mtime || 0

  #
  # Get file checksum of file for scope.
  #
  getFileChecksum: (file) ->
    return null unless _.isString(file) && file.length > 0
    return null unless @file.exists(file)

    @getFileData(file).checksum || null

  #
  # Get file timestamp/checksum of file for scope.
  #
  getFileData: (file) ->
    return null unless _.isString(file) && file.length > 0
    return null unless @file.exists(file)

    {
      mtime: Fs.statSync(file).mtime.getTime()
      checksum: @_getFileChecksum().hexDigest(file)
    }

  # ----------------------------------------------------------
  # private

  # @nodoc
  _getFileChecksum: ->
    @file.checksum

  # @nodoc
  _loadMapping: ->
    try
      @file.readJSON(@getFilePath()) || {}
    catch e
      @naspi.logger.writelnWarn "No file to read: #{@getFilePath()}"
      {}

  # @nodoc
  _writeCache: ->
    @file.writeJSON(@getFilePath(), (@_mapping || {}), { prettyPrint: true })

  # @nodoc
  _hasChanged: (file, scope) ->
    return true if @getTimestamp(file, scope) <= 0
    return false unless @_hasChangedTimestamp(file, scope)

    @_hasChangedContent(file, scope)

  # @nodoc
  _hasChangedTimestamp: (file, scope) ->
    @getTimestamp(file, scope) != @getFileTimestamp(file)

  # @nodoc
  _hasChangedContent: (file, scope) ->
    @getChecksum(file, scope) != @getFileChecksum(file)






