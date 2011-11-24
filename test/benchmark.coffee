config = require './config'
nzb = require '../src/nzb'
fs = require 'fs'
util = require 'util'
exec = require('child_process').exec
buffertools = require 'buffertools'

# set up test variables
BENCHMARK_SIZE_MB = 5
buffer = []
input = fs.createReadStream './test/fixtures/decoder_encoded.bin', 
  flags: 'r'
  encoding: null
  mode: 0666
  bufferSize: 64 * 1024
file1 =
  directory: './test/'
  name: 'decoder.bin'
  segments: []
file2 =
  directory: './test/'
  name: 'decoder_diff.bin'
  segments: []

input.on 'data', (data) ->
  buffer.push data

input.on 'end', ->
  # clone the data segment to fill the benchmark size
  # each segment is 250kb decoded
  buffer = buffertools.concat.apply(buffertools, buffer)
  for num in [1..BENCHMARK_SIZE_MB * 4]
    clone = new Buffer(buffer.length)
    buffer.copy clone
    file1.segments.push
      data: clone
  clone = new Buffer(buffer.length)
  buffer.copy clone
  file2.segments.push
    data: clone
  
  # run the test
  start = +new Date
  decoder = new nzb.Decoder
  path1 = decoder.decode file1
  duration = +new Date - start
  path2 = decoder.decode file2
  
  speed = (BENCHMARK_SIZE_MB / (duration / 1000)).toFixed(2) + ' mb/sec'
  exec 'diff ./test/fixtures/decoder_decoded.bin ' + path2, (err, stdout, stderr) ->
    if not stdout
      util.log 'Decoder: SUCCESS @ ' + speed
    else
      util.log 'Decoder: FAILURE @ ' + speed
    fs.unlink path1
    fs.unlink path2
