_ = require('lodash')

#
# Recursive merging
#
_.mergeRecursive = (objA, objB, mergeArray = false) ->
  _.merge {}, objA, objB, (a, b) =>
    return a.concat(b) if mergeArray == true && _.isArray(a)
    return _.mergeRecursive(a, b) if !_.isArray(a) && _.isObject(a) && !_.isRegExp(a) && !_.isRegExp(b)

    b

#
# Better inject syntax
#
_.inject = (collection, memo, iteratee) ->
  _.reduce collection, iteratee, memo

# export
module.exports = _