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

// Nodejs libs.
var fs = require('fs');
var path = require('path');

exports.print = function(name) {
  var code = 0;
  var filepath = path.join(__dirname, '../completion', name);
  var output;
  try {
    // Attempt to read shell completion file.
    output = String(fs.readFileSync(filepath));
  } catch (err) {
    code = 5;
    output = 'echo "Specified naspi shell auto-completion rules ';
    if (name && name !== 'true') {
      output += 'for \'' + name + '\' ';
    }
    output += 'not found."';
  }

  console.log(output);
  process.exit(code);
};