util = require 'util'
Events = require 'events'

# Export the child classes
nzb =
  Connection: require('./connection').Connection
  Decoder: require('./decoder').Decoder
  Downloader: require('./downloader').Downloader
  Parser: require('./parser').Parser
  Pool: require('./pool').Pool

# Export a singleton instance of the downloader along with the child classes
module.exports = new nzb.Downloader
for prop, value of nzb
  module.exports[prop] = value
