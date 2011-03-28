config = require './config'
NZB = require '../src/nzb'

pool = new NZB.Pool(config.pool)
pool.addNzb './test/test.nzb'
