util = require 'util'
Events = require 'events'
Connection = require('./connection').Connection
Pool = require('./pool').Pool

class Downloader extends Events.EventEmitter
  constructor: (@options) ->
    @configure @options
  
  # Add an NZB to the download list
  #   ref     (String) File location, URL, or NZB text
  # Returns
  #   (String) The NZB's ID
  add: (ref) ->
    -1
  
  # Changes the server configuration of the NZB downloader
  configure: (@options) ->
    @options or= {}
  
  # Change the priority of an NZB
  #   id      (String)
  #   index   (Number) 0 = top, -1 = bottom, N = index
  # Returns
  #   (Number) The new index
  move: (id, index) ->
    0
    
  # Remove an NZB from the download list
  #   id      (String)
  # Returns
  #   (Boolean) Success/failure
  remove: (id) ->
    false
  
  # Retrieve the current status of the NZB downloader
  # Returns
  #   (Object) Status object
  status: ->
    {}
    
exports.Downloader = Downloader