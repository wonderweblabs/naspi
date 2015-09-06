_               = require 'lodash'
AbstractLogger  = require './abstract'

module.exports = class DefaultLogger extends AbstractLogger

  constructor: (naspi) ->
    super

    @enabled = _.contains([true, 'true'], @naspi.option('verbose'))