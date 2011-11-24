{print} = require 'sys'
{spawn} = require 'child_process'

exec = (command, options) ->
  options = [options] if not (options instanceof Array)
  cmd = spawn command, options
  cmd.stdout.on 'data', (data) -> print data.toString()
  cmd.stderr.on 'data', (data) -> print data.toString()
  
brew = (options) ->
  exec 'coffee', options

build = (watch) ->
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch
  brew options

test = (suite) ->
  exec 'vows', 'test/' + suite

task 'build', 'Compile source code', ->
  build()

task 'dev', 'Compile source code (watch)', ->
  build(true)

task 'benchmark', 'Benchmarks the library', ->
  brew ['test/benchmark.coffee']

task 'test', 'Run all tests', ->
  invoke 'test-connection'
  invoke 'test-decoder'
  invoke 'test-downloader'
  invoke 'test-nzb'
  invoke 'test-parser'
  invoke 'test-pool'

task 'test-connection', 'Run connection tests', ->
  test 'connection'
  
task 'test-decoder', 'Run decoder tests', ->
  test 'decoder'
  
task 'test-downloader', 'Run downloader tests', ->
  test 'downloader'
  
task 'test-nzb', 'Run base library tests', ->
  test 'nzb'
  
task 'test-parser', 'Run parser tests', ->
  test 'parser'
  
task 'test-pool', 'Run pool tests', ->
  test 'pool'
