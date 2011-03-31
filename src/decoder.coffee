Events = require 'events'
util = require 'util'
fs = require 'fs'
buffertools = require 'buffertools'

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
        output.write @decodeSegment(segment.data)
      else
        util.log 'MISSING DATA'
    output.end()
    
    return path
    
  decodeSegment: (buffer) ->
    # split up into line buffers
    lines = []
    index = 0
    for i in [0..buffer.length - 1]
      if buffer[i] in LINEBREAKS or i is buffer.length - 1
        lines.push buffer.slice(index, i) if index isnt i
        index = i + 1
    
    # capture the encoded data
    data = null
    capturing = no
    for lineBuffer in lines
      line = lineBuffer.toString()
      capturing = yes if not capturing and line.match(/^=ybegin/)
      break if line.match(/^=yend/)
      
      # capture actual data
      if capturing and not line.match(/^=y(begin|part)/)
        data = if not data then lineBuffer else data.concat(lineBuffer)
    
    return new Buffer(@decodeLine data)
  
  # returns an array instead of a buffer
  decodeLine: (buffer) ->
    decoded = []
    for i in [0..buffer.length - 1]
      # handle escaped characters
      if buffer[i] is 0x3D and buffer[i+1] and buffer[i+1] in YEnc.ESCAPED
        decoded.push buffer[i+1] - 42 - 64
        ++i
      # but otherwise just decode the byte
      else
        decoded.push (buffer[i] + 256 - 42) % 256
    
    util.log decoded.length
    return decoded
    
Encoding =
  UNKNOWN: 0
  YENC: 1

YEnc = 
  ESCAPED: [64+0, 64+9, 64+10, 64+13, 64+27, 64+32, 64+46, 64+61]
  
LINEBREAKS = [0x0D, 0x0A]
    
exports.Decoder = Decoder
