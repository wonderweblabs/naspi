_             = require 'lodash'
path          = require 'path'
AbstractFile  = require './abstract'

module.exports = class DestinationFile extends AbstractFile

  constructor: (@naspi, file, sourceFile, options = {}) ->
    if !@naspi.file.isFile(file) && options.expand == true
      @naspi.file.mkdir(file)

    if @naspi.file.isDir(file)
      if options.expand == true
        options.cwd = file
        file = sourceFile.getRelativePath()
      else
        file = path.join(file, sourceFile.getBasename())

    super(@naspi, file, options)
