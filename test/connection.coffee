vows = require 'vows'
assert = require 'assert'
events = require 'events'
config = require './config'
nzb = require '../src/nzb'

vows.describe('Connection')
  .addBatch(
  
    'when creating a normal connection':
      topic: ->
        promise = new events.EventEmitter
        connection = new nzb.Connection(config.normal)
        connection.on 'error', ->
          promise.emit 'error', connection
          connection.disconnect()
        connection.on 'ready', ->
          promise.emit 'success', connection
          connection.disconnect()
        connection.connect()
        return promise
      'should emit ready event when connected': (err, res) ->
        assert.ok res.ready
    
    'when creating a secure connection':
      topic: ->
        promise = new events.EventEmitter
        connection = new nzb.Connection(config.secure)
        connection.on 'error', ->
          promise.emit 'error', connection
          connection.disconnect()
        connection.on 'ready', ->
          promise.emit 'success', connection
          connection.disconnect()
        connection.connect()
        return promise
      'should emit ready event when connected': (err, res) ->
        assert.ok res.ready
        
  )
  .export(module)
