util = require 'util'
config = require './config'
NZB = require '../src/nzb'

parser = new NZB.Parser
parser.on 'parse', (model) ->
  for file in model.files
    util.log 'FILE: ' + file.name + ' (' + file.parts + ' parts, ' + file.size + ' bytes)'
    util.log '  GROUPS: ' + file.groups.join(', ')
    util.log '    SEGMENT ' + segment.number + ' (' + segment.bytes + '): ' + segment.message for segment in file.segments
parser.fromFile './test/test.nzb'
 