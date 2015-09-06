###
 * Implementation copied from https://github.com/gruntjs/grunt-cli
 * and modified for naspi.
 *
 * https://github.com/wonderweblabs/naspi
 *
 * Copyright (c) 2015 Sascha Hillig, wonderweblabs, contributors
 * Licensed under the MIT license.
 * https://github.com/wonderweblabs/naspi/blob/master/LICENSE
 *
###

_         = require 'lodash'
fs        = require 'fs'
YAML      = require 'js-yaml'
rimraf    = require 'rimraf'
glob      = require 'glob'
findup    = require 'findup-sync'
iconv     = require 'iconv-lite'
path      = require 'path'
Minimatch = require 'minimatch'

###
 * File module
###
module.exports = class File

  ###
  The default file encoding to use.
  ###
  defaultEncoding: 'utf8'

  ###
  Whether to preserve the BOM on file.read rather than strip it.
  ###
  preserveBOM: false

  ###
  Path separator regex
  ###
  pathSeparatorRe: /[\/\\]/g

  ###
  The "ext" option refers to either everything after the first dot (default)
  or everything after the last dot.
  ###
  extDotRe:
    first: /(\.[^\/]*)?$/
    last: /(\.[^\/\.]*)?$/

  ###
  checksum checker
  ###
  checksum: null

  ###
  change tracker
  ###
  changeTracker: null

  ###
  bowerBuildFile
  ###
  bowerBuildFile: null

  ###
  constructor
  ###
  constructor: (@naspi) ->

  ###
  loader
  ###
  load: ->
    @checksum       = new (require('./checksum'))(@naspi, @)
    @changeTracker  = new (require('./change_tracker'))(@naspi, @)
    @bowerBuildFile = new (require('./bower_build_file'))(@naspi, @)

  ###
  # throwError
  ###
  throwError: (msg, origError) ->
    @naspi.logger.throwError(msg, origError)

  ###
  Change the current base path (ie, CWD) to the specified path.
  ###
  setBase: =>
    dirpath = path.join.apply(path, arguments)
    process.chdir(dirpath)
    null

  ###
  Process specified wildcard glob patterns or filenames against a
  callback, excluding and uniquing files in the result set.
  @param  {[String]}
  @param  {Function}
   *
  @return {[String]}
  ###
  processPatterns: (patterns, fn) =>
    result = []

    _.flatten(patterns).forEach (pattern) ->
      exclusion = pattern.indexOf('!') is 0   # If the first character is ! it should be omitted
      pattern = pattern.slice(1) if exclusion # If the pattern is an exclusion, remove the !
      matches = fn(pattern)                   # Find all matching files for this pattern.

      if exclusion  # If an exclusion, remove matching files.
        result = _.difference result, matches
      else          # Otherwise add matching files.
        result = _.union result, matches

    result

  ###
  Match a filepath or filepaths against one or more wildcard patterns. Returns
  all matching filepaths.
  ###
  match: (options, patterns, filepaths) =>
    if !_.isPlainObject(options)
      filepaths = patterns
      patterns = options
      options = {}

    # Return empty set if either patterns or filepaths was omitted.
    return [] if patterns is null or filepaths is null

    # Normalize patterns and filepaths to arrays.
    # Return empty set if there are no patterns or filepaths.
    patterns  = [ patterns ]  if !Array.isArray(patterns)
    filepaths = [ filepaths ] if !Array.isArray(filepaths)
    return [] unless _.any(patterns) && _.any(filepaths)

    # Return all matching filepaths.
    return @processPatterns patterns, (pattern) => Minimatch.match(filepaths, pattern, options)

  ###
  Match a filepath or filepaths against one or more wildcard patterns. Returns
  true if any of the patterns match.
  @return {Boolean}
  ###
  isMatch: =>
    @match.apply(@, arguments).length > 0

  ###
  Return an array of all file paths that match the given wildcard patterns.
  @return {[String]}
  ###
  expand: =>
    args      = _.toArray(arguments)
    options   = if _.isPlainObject(args[0]) then args.shift() else {}
    patterns  = if _.isArray(args[0]) then args[0] else args
    return [] unless _.any(patterns)

    # Return all matching filepaths.
    matches = @processPatterns(patterns, (pattern) => glob.sync(pattern, options) )
    return matches unless options.filter

    # Filter result set
    matches.filter (filepath) =>
      filepath = path.join (options.cwd || ''), filepath

      try
        if _.isFunction(options.filter)
          return options.filter filepath
        else # If the file is of the right type and exists, this should work.
          return fs.statSync(filepath)[options.filter]()
      catch e # Otherwise, it's probably not the right type.
        return false

  ###
  Build a multi task "files" object dynamically.
  ###
  expandMapping: (patterns, destBase, options) =>
    files       = []
    fileByDest  = {}
    options     = _.defaults {}, options, {
      extDot: 'first'
      rename: (destBase, destPath) => path.join((destBase || ''), destPath)
    }

    @expand(options, patterns).forEach (src) =>
      destPath  = src
      destPath  = path.basename(destPath) if options.flatten
      destPath  = destPath.replace(@extDotRe[options.extDot], options.ext) if 'ext' in options
      dest      = options.rename(destBase, destPath, options)
      src       = path.join(options.cwd, src) if options.cwd

      # Normalize filepaths to be unix-style.
      dest  = dest.replace @pathSeparatorRe, '/'
      src   = src.replace @pathSeparatorRe, '/'

      # Map correct src path to dest path.
      if fileByDest[dest] # If dest already exists, push this src onto that dest's src array.
        fileByDest[dest].src.push(src)
      else                # Otherwise create a new src-dest file mapping object.
        files.push
          src: [src]
          dest: dest

        # And store a reference for later use.
        fileByDest[dest] = files[files.length - 1]

    files

  ###
  Like mkdir -p. Create a directory and any intermediary directories.
  ###
  mkdir: (dirpath, mode) =>
    return if @naspi.option('no-write') == true

    # Set directory mode in a strict-mode-friendly way.
    mode = parseInt('0777', 8) & (~process.umask()) if mode == null

    dirpath.split(@pathSeparatorRe).reduce((parts, part) =>
      parts   += part + '/'
      subpath  = path.resolve(parts)

      if !@exists(subpath)
        try fs.mkdirSync(subpath, mode)
        catch e
          @throwError "Unable to create directory \"#{subpath}\" (Error code: #{e.code}).", e

      return parts
    , '')

  ###
  Recurse into a directory, executing callback for each file.
  ###
  recurse: (rootdir, callback, subdir) =>
    abspath = if subdir then path.join(rootdir, subdir) else rootdir

    fs.readdirSync(abspath).forEach (filename) =>
      filepath = path.join(abspath, filename)

      if fs.statSync(filepath).isDirectory()
        @recurse(rootdir, callback, path.join(subdir || '', filename || ''))
      else
        callback(filepath, rootdir, subdir, filename)

  ###
  Read a file, return its contents.
  ###
  read: (filepath, options) =>
    options = {} if !options
    @naspi.verbose.write "Reading #{filepath} ... "

    try
      contents = fs.readFileSync(String(filepath))

      # If encoding is not explicitly null, convert from encoded buffer to a string.
      if options.encoding isnt null
        contents = iconv.decode(contents, options.encoding || @defaultEncoding)

        # Strip any BOM that might exist.
        contents = contents.substring(1) if !@preserveBOM && contents.charCodeAt(0) is 0xFEFF

      @naspi.verbose.writeOk('ok\n')
      return contents
    catch e
      @throwError "Unable to read \"#{filepath}\" file (Error code: #{e.code}).", e

  ###
  Read a file, parse its contents, return an object.
  ###
  readJSON: (filepath, options) =>
    src = @read filepath, options
    @naspi.verbose.write "Parsing #{filepath} ... "

    try
      result = JSON.parse(src)
      @naspi.verbose.writeOk('ok\n')
      return result
    catch e
      @verboseError()
      @throwError "Unable to parse \"#{filepath}\" file (#{e.message}).", e

  ###
  Read a YAML file, parse its contents, return an object.
  ###
  readYAML: (filepath, options) =>
    src = @read filepath, options
    @naspi.verbose.write "Parsing #{filepath} ... "

    try
      result = YAML.load(src)
      @naspi.verbose.writeOk('ok\n')
      return result
    catch e
      @verboseError()
      @throwError "Unable to parse \"#{filepath}\" file (#{e.problem}).", e

  ###
  Write a file.
  ###
  write: (filepath, contents, options) =>
    options = {} if !options
    nowrite = @naspi.option('no-write')
    @naspi.verbose.write "#{if nowrite then 'Not actually writing ' else 'Writing '} #{filepath}..."

    @mkdir(path.dirname(filepath))

    try
      # If contents is already a Buffer, don't try to encode it. If no encoding
      # was specified, use the default.
      if !Buffer.isBuffer(contents)
        contents = iconv.encode(contents, options.encoding || @defaultEncoding)

      # Actually write file.
      fs.writeFileSync(filepath, contents) if !nowrite
      @naspi.verbose.writeOk('ok\n')
      return true
    catch e
      @verboseError()
      @throwError "Unable to write \"#{filepath}\" file (Error code: #{e.code}).", e

  ###
  writeJSON
  ###
  writeJSON: (filepath, json, options) =>
    spaces  = if options.prettyPrint == true then 4 else 0
    json    = JSON.stringify((json || {}), null, spaces)

    @write(filepath, json, options)

  ###
  Read a file, optionally processing its content, then write the output.
  Or read a directory, recursively creating directories, reading files,
  processing content, writing output.
  ###
  copy: (srcpath, destpath, options) =>
    if @isDir(srcpath)
      # Copy a directory, recursively. Explicitly create new dest directory.
      @mkdir(destpath)

      # Iterate over all sub-files/dirs, recursing.
      fs.readdirSync(srcpath).forEach (filepath) =>
        @copy(path.join(srcpath, filepath), path.join(destpath, filepath), options)
    else
      # Copy a single file.
      @_copy(srcpath, destpath, options)

  ###
  Read a file, optionally processing its content, then write the output.
  ###
  _copy: (srcpath, destpath, options) =>
    options = {} if !options

    # If a process function was specified, and noProcess isn't true or doesn't
    # match the srcpath, process the file's source.
    process = options.process && options.noProcess isnt true &&
      !(options.noProcess && @isMatch(options.noProcess, srcpath))

    # If the file will be processed, use the encoding as-specified. Otherwise,
    # use an encoding of null to force the file to be read/written as a Buffer.
    readWriteOptions = if process then options else { encoding: null }

    # Actually read the file.
    contents = @read(srcpath, readWriteOptions)

    if process
      @naspi.verbose.write 'Processing source ... '
      try
        contents = options.process(contents, srcpath, destpath)
        @naspi.verbose.writeOk('ok\n')
      catch e
        @naspi.verbose.writeError('error\n')
        @throwError "Error while processing \"#{srcpath}\" file.", e

    if contents is false
      @naspi.verbose.writeln 'Write aborted.'
    else
      @write(destpath, contents, readWriteOptions)

  ###
  Delete folders and files recursively
  ###
  delete: (filepath, options) =>
    filepath  = String(filepath)
    nowrite   = @naspi.option('no-write')
    options   = { force: @naspi.option('force') || false } if !options

    @naspi.verbose.write "#{if nowrite then 'Not actually deleting ' else 'Deleting '} #{filepath} ... "

    if !@exists(filepath)
      @naspi.verbose.writeError 'error\n'
      @naspi.verbose.writelnWarn 'Cannot delete nonexistent file.'
      return false

    # Only delete cwd or outside cwd if --force enabled. Be careful, people!
    if !options.force
      if @isPathCwd(filepath)
        @naspi.verbose.writeError 'error\n'
        @naspi.verbose.writelnWarn 'Cannot delete the current working directory.'
        return false
      else if !@isPathInCwd(filepath)
        @naspi.verbose.writeError 'error\n'
        @naspi.verbose.writelnWarn 'Cannot delete files outside the current working directory.'
        return false

    try
      rimraf.sync(filepath) if !nowrite
      @naspi.verbose.writeOk('ok\n')
      return true
    catch e
      @naspi.verbose.writeError 'error\n'
      @throwError "Unable to delete \"#{filepath}\" file (#{e.message}).", e

  ###
  True if the file path exists.
  ###
  exists: =>
    filepath = path.join.apply(path, arguments)
    return fs.existsSync(filepath)

  ###
  True if the file is a symbolic link.
  ###
  isLink: =>
    filepath = path.join.apply(path, arguments)
    return @exists(filepath) && fs.lstatSync(filepath).isSymbolicLink()

  ###
  True if the path is a directory.
  ###
  isDir: =>
    filepath = path.join.apply(path, arguments)
    return @exists(filepath) && fs.statSync(filepath).isDirectory()

  ###
  True if the path is a file.
  ###
  isFile: =>
    filepath = path.join.apply(path, arguments)
    return @exists(filepath) && fs.statSync(filepath).isFile()

  ###
  Is a given file path absolute?
  ###
  isPathAbsolute: =>
    filepath = path.join.apply(path, arguments)
    return path.resolve(filepath) is filepath.replace(/[\/\\]+$/, '')

  ###
  Do all the specified paths refer to the same path?
  ###
  arePathsEquivalent: (first) =>
    first = path.resolve(first)

    for argument in arguments
      return false if first isnt path.resolve(argument)

    return true

  ###
  Are descendant path(s) contained within ancestor path? Note: does not test
  if paths actually exist.
  ###
  doesPathContain: (ancestor) =>
    ancestor = path.resolve(ancestor)

    for argument in arguments
      relative = path.relative(path.resolve(argument), ancestor)
      return false if relative is '' || /\w+/.test(relative)

    return true

  ###
  Test to see if a filepath is the CWD.
  ###
  isPathCwd: =>
    filepath = path.join.apply(path, arguments)

    try
      return @arePathsEquivalent(fs.realpathSync(process.cwd()), fs.realpathSync(filepath))
    catch e
      return false

  ###
  Test to see if a filepath is contained within the CWD.
  ###
  isPathInCwd: =>
    filepath = path.join.apply(path, arguments)

    try
      return @doesPathContain(fs.realpathSync(process.cwd()), fs.realpathSync(filepath))
    catch e
      return false

