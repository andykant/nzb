Events = require 'events'
util = require 'util'
Connection = require('./connection').Connection
Parser = require('./parser').Parser

class Pool extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    
    # create queues
    @queue = []
    @nzbs = []
    
    # create connections
    @connections = []
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
      for file in nzb.files
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
    # add the connection to the waiting list if there isn't any work
    if @queue.length is 0
      @disconnect()
      return
    
    # get a connection
    if conn
      item = @queue.shift()
      @log conn, 'GET', item.file.name, item.segment.message + ' (' + item.segment.number + '/' + item.file.parts + ')'
      conn.get(item.file.groups[0], item.segment.message)
  
  connect: ->
    conn.connect() for conn in @connections
  
  disconnect: ->
    conn.disconnect() for conn in @connections

exports.Pool = Pool
