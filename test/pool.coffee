config = require './config'
nzb = require '../src/nzb'
fs = require 'fs'
util = require 'util'

pool = new nzb.Pool(config.pool)

results = []
pool.on 'file', (path, file) ->
  file.path = path
  results.push file
  
  setTimeout(->
    if results.length is 3
      for file in results
        util.log file.name + ': ' + (if fs.statSync(file.path).size is file.size then 'SUCCESS' else 'FAILURE')
        fs.unlink file.path
  , 1000)

pool.addNzb './test/fixtures/test.nzb'
