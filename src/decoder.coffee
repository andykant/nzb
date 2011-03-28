Events = require 'events'
util = require 'util'

class Decoder extends Events.EventEmitter
  constructor: (@options) ->
    @options or= {}
    
exports.Decoder = Decoder
