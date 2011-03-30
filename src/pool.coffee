Events = require 'events'
util = require 'util'
Connection = require('./connection').Connection
Parser = require('./parser').Parser
Decoder = require('./decoder').Decoder

class Pool extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    @decoder = new Decoder
    
    # create queues
    @queue = []
    @nzbs = []
    
    # create connections
    @connections = []
    @active = []
    for number in [1..@options.connections or 1]
      do =>
        # create a connection
        options = 
          number: number
        for prop, value of @options
          options[prop] = value
        conn = new Connection(options)
        @connections.push conn
      
        # assign listeners
        conn.on 'ready', =>
          @process(conn)
        conn.on 'segment', (group, message, data) =>
          @log conn, 'SEGMENT', group, message, data
          @process(conn)
    
    # set up parser
    @parser = new Parser
    @parser.on 'parse', (nzb) =>
      directory = (nzb.path and (match = nzb.path.match(/^(.*?)[^\/]+$/)) and match[1]) or './'
    
      for file in nzb.files
        file.progress = 0
        file.directory = directory
        for segment in file.segments
          @queue.push
            file: file
            segment: segment
      @connect()
  
  log: (conn, type, group, message, data) ->
    util.log 'Pool #' + ((conn and conn.options.number) or 0) + ' - ' + type + ' ' + group + ' ' + message
    # util.log data
  
  addNzb: (path) ->
    @parser.fromFile path
    
  process: (conn) ->
    # check for an empty queue
    if @queue.length is 0
      # remove the connection from the active pool
      if conn and (index = @active.indexOf conn) >= 0
        @active.splice index, 1
      
      # wait to disconnect until all connections are finished
      if @active.length is 0
        @disconnect()
      return
    
    # get a connection
    if conn and @queue.length > 0
      item = @queue.shift()
      @active.push conn if conn not in @active
      @log conn, 'GET', item.file.name, item.segment.message + ' (' + item.segment.number + '/' + item.file.parts + ')'
      conn.get item.file.groups[0], item.segment.message, (data) =>
        item.file.progress += item.segment.bytes
        item.segment.data = data
        util.log 'PROGRESS ' + item.file.name + ': ' + item.file.progress + ' / ' + item.file.size
        @decodeFile item.file if item.file.progress is item.file.size
        
  decodeFile: (file) ->
    util.log 'TIME TO DECODE: ' + file.name + ' TO ' + file.directory + file.name
    @decoder.decode file
  
  connect: ->
    conn.connect() for conn in @connections
  
  disconnect: ->
    conn.disconnect() for conn in @connections

exports.Pool = Pool
