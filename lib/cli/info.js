/*
 * Implementation copied from https://github.com/gruntjs/grunt-cli
 * and modified for naspi.
 *
 * https://github.com/wonderweblabs/naspi
 *
 * Copyright (c) 2015 Sascha Hillig, wonderweblabs, contributors
 * Licensed under the MIT license.
 * https://github.com/wonderweblabs/naspi/blob/master/LICENSE
 *
 */

'use strict';

// Project metadata.
var pkg = require('../../package.json');

// Display naspi version.
exports.version = function() {
  console.log('naspi v' + pkg.version);
};

// Show help, then exit with a message and error code.
exports.fatal = function(msg, code) {
  exports.helpHeader();
  console.log('Fatal error: ' + msg);
  console.log('');
  exports.helpFooter();
  process.exit(code);
};

// Show help and exit.
exports.help = function() {
  exports.helpHeader();
  exports.helpFooter();
  process.exit();
};

// Help header.
exports.helpHeader = function() {
  console.log('naspi: ' + pkg.description + ' (v' + pkg.version + ')');
  console.log('');
};

// Help footer.
exports.helpFooter = function() {
  [
    'If you\'re seeing this message, the graspi installation wasn\'t found for the',
    'current project. Please install naspi - npm install naspi --save.',
    'More information under:',
    '',
    'https://github.com/wonderweblabs/naspi',
    '',
  ].forEach(function(str) { console.log(str); });
};