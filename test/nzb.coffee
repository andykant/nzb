fs = require 'fs'
util = require 'util'
vows = require 'vows'
assert = require 'assert'
config = require './config'
nzb = require '../src/nzb'

vows.describe('NZB')
  .addBatch(
    'when loading the NZB library':
      topic: nzb
      'should expose a singleton Downloader instance API': (topic) ->
        assert.isFunction topic.add
        assert.isFunction topic.configure
        assert.isFunction topic.move
        assert.isFunction topic.remove
        assert.isFunction topic.status
      'should contain references to all child classes': (topic) ->
        assert.isFunction topic.Connection
        assert.isFunction topic.Decoder
        assert.isFunction topic.Downloader
        assert.isFunction topic.Parser
        assert.isFunction topic.Pool
  )
  .export(module)
