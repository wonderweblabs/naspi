_     = require './util/lodash_extensions'
exit  = require 'exit'
Q     = require 'q'

#
# Main naspi module. All scripts start from here.
#
module.exports = new (class Naspi

  logger:         null
  verbose:        null
  file:           null
  exec:           null
  notifier:       null
  options:        null
  pkgRunner:      null
  pkgWatcher:     null
  pkgs:           {}

  run: =>
    @options  = new (require('./options/options'))(@)
    @logger   = new (require('./logger/default'))(@)
    @verbose  = new (require('./logger/verbose'))(@)
    @file     = new (require('./file/file_util'))(@)
    @exec     = new (require('./util/exec'))(@)
    @notifier = new (require('./notifier/notifier'))(@)

    @options.load()
    @file.load()

    @logger     = new (require('./logger/default'))(@)
    @verbose    = new (require('./logger/verbose'))(@)
    @pkgReader  = new (require('./util/bower_package_reader'))(@)
    @pkgRunner  = new (require('./util/package_runner'))(@)

    @pkgReader.resolve()

    if @options.option('watch') == true
      @pkgWatcher = new (require('./util/package_watcher'))(@)
      @pkgWatcher.watch()
    else
      @pkgRunner.run()

  option: (key, env = null) =>
    @options.option(key, env)

  exit: (code) =>
    exit(code)

)