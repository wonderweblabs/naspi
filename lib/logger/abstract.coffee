_         = require 'lodash'
Color     = require 'colors'
NodeUtil  = require 'util'

module.exports = class AbstractLogger

  enabled: false

  debug: false

  outStream: process.stdout

  constructor: (@naspi) ->
    @debug = _.contains([true, 'true'], @naspi.option('debug'))

  write:        (msg...) -> @_writeEach(msg)
  writeln:      (msg...) -> @_writelnEach(msg)
  writeDebug:   (msg...) -> @_writeEach(msg)    if @debug
  writelnDebug: (msg...) -> @_writelnEach(msg)  if @debug
  writeInfo:    (msg...) -> @_writeEach(msg, 'blue')
  writelnInfo:  (msg...) -> @_writelnEach(msg, 'blue')
  writeOk:      (msg...) -> @_writeEach(msg, 'green')
  writelnOk:    (msg...) -> @_writelnEach(msg, 'green')
  writeWarn:    (msg...) -> @_writeEach(msg, 'yellow')
  writelnWarn:  (msg...) -> @_writelnEach(msg, 'yellow')
  writeError:   (msg...) -> @_writeEach(msg, 'red')
  writelnError: (msg...) -> @_writelnEach(msg, 'red')

  fatal: (msg...) ->
    @_writeln([''])
    @_writeln([''])
    @_writelnEach(msg, 'red')
    @_writelnEach(['Naspi fatal - interrupt process'], 'red')
    @naspi.exit(129)

  throwError: (msg, origError) ->
    @_writeln([''])
    @_writeln([''])
    @_writelnEach(msg, 'red')
    @_writelnEach(['Naspi fatal - interrupt process'], 'red')
    @_writeln([''])
    @_writelnEach([(origError.stack || '')], 'red')
    @naspi.exit(129)


  _writeEach: (msgs, color = null) =>
    return unless @enabled

    msgs = [msgs] unless _.isArray(msgs)

    _.each(msgs, (msg) => @_write(@_format(msg, color)))

  _writelnEach: (msgs, color = null) =>
    return unless @enabled

    msgs = [msgs] unless _.isArray(msgs)

    _.each(msgs, (msg) => @_writeln(@_format(msg, color)))

  _write: (str) =>
    return unless @enabled

    @outStream.write(@_markup(str))

  _writeln: (msg) =>
    @_write((msg || '') + '\n')

  _format: (str, color = null) =>
    str = "[null]" if _.isNull(str)
    str = "[undefined]" if _.isUndefined(str)
    str = @_prepare(str || '')

    str = switch color
      when 'blue'   then str.blue
      when 'green'  then str.green
      when 'yellow' then str.yellow
      when 'red'    then str.red
      else str

    @_markup(str)

  # Make _foo_ underline.
  # Make *foo* bold.
  _markup: (str) =>
    str = (str || '').replace(/(\s|^)_(\S|\S[\s\S]+?\S)_(?=[\s,.!?]|$)/g, '$1' + '$2'.underline)
    str.replace(/(\s|^)\*(\S|\S[\s\S]+?\S)\*(?=[\s,.!?]|$)/g, '$1' + '$2'.bold)

  _prepare: (msg) ->
    msg or= ''
    msg = JSON.stringify(msg, null, 3) unless _.isString(msg)
    msg
