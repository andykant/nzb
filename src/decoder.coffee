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
    
    for segment, i in file.segments
      if segment.data
        seg = @decodeSegment(segment.data)
        util.log seg.length + ' (' + (i+1) + '/' + file.segments.length + ')'
        output.write seg
      else
        util.log 'MISSING DATA'
    output.end()
    
    return path
    
  indexOf: (buffer, string) ->
    # this doesn't always work with concatenated buffers:
    # return buffer.indexOf(string)
    for i in [0..buffer.length - string.length - 1]
      return i if buffer.slice(i, i + string.length).toString() is string
    return -1
    
  decodeSegment: (buffer, method) ->
    if not method or method is 1
      # split up into line buffers
      lines = []
      start = 0
      for i in [0..buffer.length - 1]
        if buffer[i] in LINEBREAKS or i is buffer.length - 1
          lines.push buffer.slice(start, i) if start isnt i
          start = i + 1
    
      # capture the encoded data
      data = []
      capturing = no
      for lineBuffer in lines
        line = lineBuffer.toString()
        if not capturing and (match = line.match(YEnc.BEGIN))
          capturing = yes
          lineSize = parseInt(match[3], 10)
        else if match = line.match(YEnc.END)
          lineSize = null
          break
      
        # capture actual data
        if capturing and not line.match(/^=y/)
          if lineBuffer[0] is 0x2E and lineBuffer[1] is 0x2E
            data.push lineBuffer.slice(1, lineBuffer.length)
          else
            data.push lineBuffer
    
      return @decodeBuffer buffertools.concat.apply(buffertools, data)
    # method 2 is fast but fails
    # method 3 is extremely slow but is successful
    else if method in [2,3]
      buff = buffer.slice(index = @indexOf(buffer, '=ybegin'), buffer.length)
      begin = buffer.slice(index, index = @indexOf(buff, CRLF) + index + 2)
      buff = buffer.slice(index, buffer.length)
      if (index2 = @indexOf(buff, '=ypart')) > -1
        buff = buffer.slice(index = index2 + index, buffer.length)
        part = buffer.slice(index, index = @indexOf(buff, CRLF) + index + 2)
        buff = buffer.slice(index, buffer.length)
      data = buffer.slice(index, index = @indexOf(buff, '=yend') + index)
      buff = buffer.slice(index, buffer.length)
      end = buffer.slice(index, index = @indexOf(buff, CRLF) + index + 2)
    
      # util.log begin
      # util.log part if part
      # util.log 'data: ' + data.length
      # util.log end
    
      # output2.write data
    
      lineSize = null
      if match = begin.toString().match(YEnc.BEGIN)
        lineSize = parseInt(match[2], 10)
    
      partSize = null
      if match = end.toString().match(YEnc.END)
        partSize = parseInt(match[1], 10)
    
      lines = []
      # this method is pretty fast, but can result in corrupt data
      if lineSize and method is 2
        # chomp the end linebreaks
        limit = data.length - 1
        --limit while data[limit] in LINEBREAKS
      
        # grab each yEnc line
        for i in [0..limit] by lineSize
          # check for lines starting with a double-dot ("..")
          start = if data[i] is 0x2E and data[i+1] is 0x2E then i + 1 else i
        
          # append the encoded data
          if not (data[i + lineSize] in LINEBREAKS)
            lines.push data.slice(start, index = Math.min(i + lineSize + 1, limit + 1))
            ++i
          else
            lines.push data.slice(start, index = Math.min(i + lineSize, limit + 1))
        
          # chomp the linebreaks
          i += 2
      # this method is incredibly slow, but works
      else if not lineSize or method is 3
        index = 0
        while index < data.length - 1 and (index2 = @indexOf(data.slice(index, data.length), CRLF)) > -1
          # check for lines starting with a double-dot ("..")
          start = if data[index] is 0x2E and data[index+1] is 0x2E then index + 1 else index
        
          lines.push data.slice(start, Math.min(index2 + index, data.length))
          index += index2 + 2
        lines.push data.slice(index, data.length - 2)
    
      data = buffertools.concat.apply(buffertools, lines)
    
      # output3.write data
    
      decoded = @decodeBuffer data
      if decoded.length isnt partSize
        util.log begin
        util.log part
        util.log end
        # util.log 'encode: ' + data.length
        util.log 'expect: ' + (partSize or '?')
        util.log 'actual: ' + decoded.length
    
      return decoded
    
  
  # returns an array instead of a buffer
  decodeBuffer: (buffer) ->
    decoded = []
    for i in [0..buffer.length - 1]
      # handle escaped characters
      if buffer[i] is 0x3D and buffer[i+1] and buffer[i+1] in YEnc.ESCAPED
        decoded.push (buffer[i+1] - 64 - 42) % 256
        ++i
      # but otherwise just decode the byte
      else
        decoded.push (buffer[i] - 42) % 256
    
    return new Buffer(decoded)
    
Encoding =
  UNKNOWN: 0
  YENC: 1

YEnc = 
  BEGIN: /=ybegin part=(\d+) line=(\d+) size=(\d+) name=(.+)/
  PART: /=ypart begin=(\d+) end=(\d+)/
  END: /=yend size=(\d+) part=(\d+) pcrc32=([a-z0-9]+)/
  ESCAPED: [64+0, 64+9, 64+10, 64+13, 64+27, 64+32, 64+46, 64+61]
  
LINEBREAKS = [0x0D, 0x0A]
CRLF = '\r\n'
    
exports.Decoder = Decoder
