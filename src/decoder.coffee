Events = require 'events'
util = require 'util'
fs = require 'fs'

class Decoder extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    
  decode: (file) ->
    return if not file
    
    path = file.directory + file.name
    
    # create output stream
    output = fs.createWriteStream path, 
      flags: 'w'
      encoding: null
      mode: 0666
    
    for segment in file.segments
      if segment.data
        output.write segment.data
      else
        util.log 'MISSING DATA'
    
    output.end()
    
    return path
    
exports.Decoder = Decoder
