Events = require 'events'
util = require 'util'
fs = require 'fs'

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
  (&#34;|&#x22;)(.*?)(&#34;|&#x22;)
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

class Parser extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
  
  log: (message) ->
    util.log message
    
  fromFile: (path) ->
    fs.readFile(path, 'utf-8', (err, data) =>
      throw err if err
      @fromString data
    )
    
  fromString: (xml) ->
    model =
      title: ''
      files: []
      
    while file = FILE.exec(xml)
      item =
        parts: parseInt(FILE_SUBJECT_SEGMENTS.exec(file[2])[1], 10)
        name: FILE_SUBJECT_FILENAME.exec(file[2])[2]
        groups: []
        segments: []
      
      while group = GROUP.exec(file[3])
        item.groups.push group[1]
        
      while segment = SEGMENT.exec(file[3])
        item.segments.push
          bytes: parseInt(SEGMENT_BYTES.exec(segment[1])[1], 10)
          number: parseInt(SEGMENT_NUMBER.exec(segment[1])[1], 10)
          message: '<' + segment[2] + '>'
      
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
  
exports.Parser = Parser
