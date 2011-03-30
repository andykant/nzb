Events = require 'events'
util = require 'util'
fs = require 'fs'

class Parser extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
  
  log: (message) ->
    util.log message
    
  convertEntities: (str) ->
    while entity = ENTITY.exec(str)
      str = str.replace entity[0], String.fromCharCode(parseInt(entity[2], if entity[1] is 'x' then 16 else 10))
    return str
    
  fromFile: (path) ->
    fs.readFile(path, 'utf-8', (err, data) =>
      throw err if err
      @fromString data, path
    )
    
  fromString: (xml, path) ->
    model =
      path: path or null
      title: ''
      files: []
      
    while file = FILE.exec(xml)
      item =
        size: 0
        parts: parseInt(FILE_SUBJECT_SEGMENTS.exec(file[2])[1], 10)
        name: FILE_SUBJECT_FILENAME.exec(@convertEntities file[2])[1]
        groups: []
        segments: []
      
      while group = GROUP.exec(file[3])
        item.groups.push group[1]
        
      while segment = SEGMENT.exec(file[3])
        bytes = parseInt(SEGMENT_BYTES.exec(segment[1])[1], 10)
        item.size += bytes
        item.segments.push
          bytes: bytes
          number: parseInt(SEGMENT_NUMBER.exec(segment[1])[1], 10)
          message: '<' + @convertEntities(segment[2]) + '>'
          data: null
      
      # sort segments by number
      item.segments.sort (a, b) ->
        if a.number < b.number
          -1
        else if b.number < a.number
          1
        else
          0
      
      model.files.push item
    
    # sort files by filename
    model.files.sort (a, b) ->
      if a.name < b.name
        -1
      else if b.name < a.name
        1
      else
        0
    
    @emit 'parse', model
    
# regular expressions used for parsing the NZB XML document
FILE = ///
  <file .*? ( subject="(.*?)" ) .*? >
    ([\s\S]*?)
  </file>
  ///ig
FILE_SUBJECT_SEGMENTS = ///
  \(\d+/(\d+)\)
  ///
FILE_SUBJECT_FILENAME = ///
  "(.*?)"
  ///
GROUP = ///
  <group>
    (.*?)
  </group>
  ///ig
SEGMENT = ///
  <segment (.*?)>
    (.*?)
  </segment>
  ///ig
SEGMENT_BYTES = /// \b
  bytes="(\d+)"
  ///i
SEGMENT_NUMBER = /// \b
  number="(\d+)"
  ///i
ENTITY = /&#(x?)(\d+);/g
  
exports.Parser = Parser
