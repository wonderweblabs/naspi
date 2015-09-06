'use strict';

// This allows grunt to require() .coffee files.
require('coffee-script');
require('coffee-script/register');

// expose the naspi service object
module.exports = require('./naspi');