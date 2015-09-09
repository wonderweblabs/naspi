_         = require 'lodash'
path      = require 'path'
Q         = require 'q'
Abstract  = require './abstract'

###

options:
  * files   (String|[String]) required
  * cwd     (String)
  * dest    (String) required
  * filter  (function)

###
module.exports = class Copy extends Abstract

  onRun: (deferred, srcDestMap, options = {}) =>
    srcDestObjs = srcDestMap.resolve()

    _.each srcDestObjs, (srcDestObj) =>
      @naspi.file.copy(srcDestObj.src().pathFromRoot(), srcDestObj.dest().pathFromRoot())

    deferred.resolve()