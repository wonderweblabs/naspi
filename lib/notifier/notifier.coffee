_             = require 'lodash'
path          = require 'path'
Q             = require 'q'
child_process = require 'child_process'

module.exports = class Notifier

  constructor: (@naspi) ->
    # @naspi.option('notify') == true

  notify: (options = {}) =>
    return if @naspi.option('notify') == false

    options = _.defaults options, {
      title: 'naspi'
      message: ''
    }

    args = ['exec', 'terminal-notifier']
    args.push '-title'
    args.push options.title
    args.push '-message'
    args.push options.message

    if _.isString(options.subtitle)
      args.push '-subtitle'
      args.push options.subtitle

    if _.isString(options.sound)
      args.push '-sound'
      args.push options.sound

    if _.isString(options.group)
      args.push '-group'
      args.push options.group

    if _.isString(options.remove)
      args.push '-remove'
      args.push options.remove

    if _.isString(options.list)
      args.push '-list'
      args.push options.list

    if _.isString(options.activate)
      args.push '-activate'
      args.push options.activate

    if _.isString(options.sender)
      args.push '-sender'
      args.push options.sender

    if _.isString(options.appIcon)
      args.push '-appIcon'
      args.push options.appIcon

    if _.isString(options.contentImage)
      args.push '-contentImage'
      args.push options.contentImage

    if _.isString(options.open)
      args.push '-open'
      args.push options.open

    if _.isString(options.execute)
      args.push '-execute'
      args.push options.execute

    @naspi.exec.exec(Q.defer(), 'bundle', args, {})


