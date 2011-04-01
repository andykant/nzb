Events = require 'events'
tls = require 'tls'
net = require 'net'
util = require 'util'
buffertools = require 'buffertools'

class Connection extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    @data = []
  
  log: (message) ->
    # util.log @options.host + ':' + @options.port + '#' + (@options.number or 0) + ' - ' + message
    
  # connect to the server
  connect: ->
    return @socket if @socket or @connecting
    
    # updates the state of the connection to ready for requests
    ready = =>
      @ready = yes
      @log 'ready'
      @emit 'ready'
    
    # wires up socket listeners and helpers
    listen = (socket) =>
      # override the write method so that we can log requests
      socket.write = (request) =>
        logged = request.substr(0, request.length - 2)
        logged = logged.split(' ').slice(0, 2).join(' ') + ' ********' if logged.match(/^AUTHINFO/)
        @log 'REQUEST: ' + logged
        socket.__proto__.write.call(socket, request + BREAK)
      # track when the server connects
      socket.on 'connect', =>
        @connected = yes
        @log 'connect'
      # handle data responses
      socket.on 'data', (data) =>
        response = @parse data
        @log 'response: ' + response.code + ' - ' + response.message if response.code?
        
        # check for receiving data first since they don't include a response code past the first buffer
        if (response.code is Codes.RECEIVING_DATA or @receiving) and response.data
          # append the data
          if response.code is Codes.RECEIVING_DATA
            @data = [response.data]
            @receiving = yes
          else
            @data.push response.data
          
          # check for the end of the file
          if EOF.test response.data
            @receiving = no
            # make references in case these properties get overwritten
            group = @selectedGroup
            message = @message
            data = buffertools.concat.apply(buffertools, @data)
            callback = @callback
            @emit 'segment', group, message, data
            callback data if callback
        # successfully connected to the server
        else if response.code in Codes.CONNECTED
          # need to authenticate if credentials were included
          if @options.username
            @authenticate()
          else
            ready()
        # authenticated the user, but still need a password
        else if @authenticating and response.code is Codes.PASSWORD_REQUIRED
          @authenticate()
        # successfully authenticated the user (and password if applicable)
        else if response.code is Codes.AUTHENTICATED
          @authenticating = no
          @authenticated = yes
          ready()
        # handle a list of capabilities (mainly for debugging)
        else if response.code is Codes.CAPABILITIES
          @log 'capabilities: \r\n' + response.data.join(BREAK)
          @emit 'capabilities', response.data
        # group successfully selected (needed to retrieve body content)
        else if response.code is Codes.GROUP_SELECTED
          @selectedGroup = @selectingGroup
          @selectingGroup = null
          # now that the group was selected, re-attempt the message retrieval
          @get @selectedGroup, @message, @callback if @message
      socket.on 'end', =>
        @log 'end'
        @disconnect()
      socket.on 'error', (exception) =>
        @log 'error: ' + exception.message
        @disconnect()
      socket.on 'close', =>
        @log 'close'
        @disconnect()
    
    # open the connection
    @connecting = yes
    @log 'open'
    if @options.secure
      @socket = listen tls.connect(@options.port, @options.host, =>
        # emulate the connect/error events that an insecure socket would emit
        if @socket.authorized
          @socket.emit 'connect'
        else
          @socket.emit 'error', { message: 'Unauthorized' }
      )
    else
      @socket = listen net.createConnection(@options.port, @options.host)
    return @socket
  
  # authenticate with the username/password
  authenticate: ->
    return if not @connected or @authenticated or not @options.username
    
    if not @authenticating
      @authenticating = yes
      @socket.write('AUTHINFO USER ' + @options.username)
    else
      @authenticating = no
      @socket.write('AUTHINFO PASS ' + @options.password)
  
  # retrieve the capabilities for the active session (mainly for debugging sessions)
  capabilities: ->
    return if not @ready
    
    @socket.write('CAPABILITIES')
  
  # select a newsgroup
  group: (group)->
    return if not @ready
    
    @selectedGroup = null
    @socket.write('GROUP ' + group)
  
  # retrieve an article
  get: (group, message, callback) ->
    return if not @ready
    
    @message = message
    @callback = callback or null
    if not @group or @selectedGroup isnt group
      @selectingGroup = group
      @group group
    else
      @socket.write('BODY ' + @message)
  
  # parse a socket data response
  parse: (data) ->
    lines = data.toString().split(LINE)
    match = lines[0].match(RESPONSE)
    code = match and parseInt(match[1], 10)
    
    return {
      code: code
      data: ((code is Codes.RECEIVING_DATA or @receiving) and data) or (match and lines.slice(1)) or data.toString()
      message: match and match[2]
    }
  
  # disconnect and clean up
  disconnect: ->
    @ready = no
    @connecting = no
    @connected = no
    @authenticating = no
    @authenticated = no
    @receiving = no
    @selectedGroup = null
    @message = null
    @callback = null
    @data = []
    @socket.destroy() if @socket
    @socket = null

# expressions used for parsing responses
RESPONSE = /^(\d+)\s(.+?)$/
LINE = /[\r\n]+/
REST_OF_DATA = /[\r\n]+([\s\S]*)$/
EOF = /[\r\n]*\.[\r\n]+$/
BREAK = '\r\n'

# response codes
Codes =
  CAPABILITIES: 101
  CONNECTED: [200, 201]
  GROUP_SELECTED: 211
  RECEIVING_DATA: 222
  AUTHENTICATED: 281
  PASSWORD_REQUIRED: 381
  ARTICLE_NOT_FOUND: 430
  TOO_MANY_CONNECTIONS: 502
  
# convert a buffer to an array
bufferToArray = (buffer) ->
  arr = new Array(buffer.length)
  for i in [0..buffer.length - 1]
    arr[i] = buffer[i]
  return arr
    
exports.Connection = Connection
