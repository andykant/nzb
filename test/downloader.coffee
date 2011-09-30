fs = require 'fs'
util = require 'util'
vows = require 'vows'
assert = require 'assert'
config = require './config'
nzb = require '../src/nzb'

vows.describe('Downloader')
  .addBatch(
    'when creating a downloader':
      topic: new nzb.Downloader(config)
      'should expose the API': (topic) ->
        assert.isFunction topic.add
        assert.isFunction topic.configure
        assert.isFunction topic.move
        assert.isFunction topic.remove
        assert.isFunction topic.status
  )
  .export(module)
