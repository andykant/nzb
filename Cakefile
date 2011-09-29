{print} = require 'sys'
{spawn} = require 'child_process'

brew = (options) ->
  options = [options] if not options instanceof Array
  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()

build = (watch) ->
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch
  brew options

task 'build', 'Compile source code', ->
  build()

task 'dev', 'Compile source code (watch)', ->
  build(true)

task 'test', 'Run all tests', ->
  invoke 'test-connection'
  invoke 'test-decoder'
  invoke 'test-downloader'
  invoke 'test-parser'
  invoke 'test-pool'

task 'test-connection', 'Run connection tests', ->
  brew 'test/connection-test.coffee'
  
task 'test-decoder', 'Run decoder tests', ->
  brew 'test/decoder-test.coffee'
  
task 'test-downloader', 'Run downloader tests', ->
  brew 'test/downloader-test.coffee'
  
task 'test-parser', 'Run parser tests', ->
  brew 'test/parser-test.coffee'
  
task 'test-pool', 'Run pool tests', ->
  brew 'test/pool-test.coffee'
