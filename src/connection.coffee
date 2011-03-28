Events = require 'events'
tls = require 'tls'
net = require 'net'
util = require 'util'
    
RESPONSE = /^(\d+)\s(.+?)$/
LINE = /[\r\n]+/
BREAK = '\r\n'
EOF = /\r\n\.\r\n/

Codes =
  CAPABILITIES: 101
  CONNECTED: [200, 201]
  GROUP_SELECTED: 211
  RECEIVING_DATA: 222
  AUTHENTICATED: 281
  PASSWORD_REQUIRED: 381
  ARTICLE_NOT_FOUND: 430
  TOO_MANY_CONNECTIONS: 502

class Connection extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    @data = []
  
  log: (message) ->
    util.log @options.host + ':' + @options.port + '#' + (@options.number or 0) + ' - ' + message
    
  # connect to the server
  connect: ->
    return @socket if @socket or @connecting
    @connecting = yes
    
    # ready state helper
    ready = =>
      @ready = yes
      @log 'ready'
      @emit 'ready'
    
    # set up socket listeners helper
    listen = (socket) =>
      socket.write = (request) =>
        logged = request.substr(0, request.length - 2)
        logged = logged.split(' ').slice(0, 2).join(' ') + ' ********' if logged.match(/^AUTHINFO/)
        @log 'REQUEST: ' + logged
        socket.__proto__.write.call(socket, request)
      socket.on 'connect', =>
        @connected = yes
        @log 'connect'
        # socket.setEncoding('utf-8')
      socket.on 'data', (data) =>
        response = @parse data
        @log 'response: ' + response.code + ' - ' + response.message if response.code?
        
        # receiving data takes priority since it sometimes messes up responses
        if (response.code is Codes.RECEIVING_DATA or @receiving) and response.data
          # append the data
          @receiving = yes
          data = response.data.toString()
          @data.push data
          # check for the end of the file
          if EOF.test data
            @receiving = no
            @emit 'segment', @selectedGroup, @message, @data.join('')
        else if response.code in Codes.CONNECTED
          if @options.username
            @authenticate()
          else
            ready()
        else if @authenticating and response.code is Codes.PASSWORD_REQUIRED
          @authenticate()
        else if response.code is Codes.AUTHENTICATED
          @authenticating = no
          @authenticated = yes
          ready()
        else if response.code is Codes.CAPABILITIES
          @log 'capabilities: \r\n' + response.data.join(BREAK)
          @emit 'capabilities', response.data
        else if response.code is Codes.GROUP_SELECTED
          @selectedGroup = @selectingGroup
          @selectingGroup = null
          @get @selectedGroup, @message if @message
        # else if response.data
        #   @log 'data: \r\n' + response.data.join(BREAK)
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
    @log 'open'
    if @options.secure
      @socket = listen tls.connect(@options.port, @options.host, =>
        if @socket.authorized
          @socket.emit 'connect'
        else
          @socket.emit 'error', { message: 'Unauthorized' }
      )
    else
      @socket = listen net.createConnection(@options.port, @options.host)
  
  # authenticate with the username/password
  authenticate: ->
    return if not @connected or @authenticated or not @options.username
    if not @authenticating
      @authenticating = yes
      @socket.write('AUTHINFO USER ' + @options.username + BREAK)
    else
      @authenticating = no
      @socket.write('AUTHINFO PASS ' + @options.password + BREAK)
  
  # retrieve the capabilities for the active session 
  capabilities: ->
    return if not @ready
    @socket.write('CAPABILITIES' + BREAK)
  
  # select a newsgroup
  group: (group)->
    return if not @ready
    @selectedGroup = null
    @socket.write('GROUP ' + group + BREAK)
  
  # retrieve an article
  get: (group, message) ->
    return if not @ready
    @message = message
    if not @group or @selectedGroup isnt group
      @selectingGroup = group
      @group group
    else
      @socket.write('BODY ' + @message + BREAK)
  
  # parse a socket data response
  parse: (data) ->
    lines = data.toString().split(LINE)
    match = lines[0].match(RESPONSE)
    
    return {
      code: match and parseInt(match[1], 10)
      data: (@receiving and data) or (match and lines.slice(1)) or data
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
    @data = []
    @socket.destroy() if @socket
    @socket = null
    
exports.Connection = Connection
