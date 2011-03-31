config = require './config'
fs = require 'fs'
util = require 'util'
exec = require('child_process').exec
NZB = require '../src/nzb'

LINE = /[\r\n]+/
decoder = new NZB.Decoder

fs.readFile './test/fixtures/yenc_single.ntx', (err, data) ->
  path = decoder.decode
    directory: './test/'
    name: 'yenc_single.txt'
    segments: [{ data: data }]
    
  exec 'diff ./test/fixtures/yenc_single.txt ' + path, (err, stdout, stderr) ->
    if not stdout
      util.log 'yenc_single: SUCCESS'
    else
      util.log 'yenc_single: FAILURE'        
    fs.unlink path

fs.readFile './test/fixtures/yenc_multi_part1.ntx', (err1, data1) ->
  fs.readFile './test/fixtures/yenc_multi_part2.ntx', (err2, data2) ->
    path = decoder.decode
      directory: './test/'
      name: 'yenc_multi.jpg'
      segments: [{ data: data1 }, { data: data2 }]
    
    exec 'diff ./test/fixtures/yenc_multi.jpg ' + path, (err, stdout, stderr) ->
      if not stdout
        util.log 'yenc_multi: SUCCESS'
      else
        util.log 'yenc_multi: FAILURE'
      fs.unlink path
