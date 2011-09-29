util = require 'util'
Events = require 'events'

# Export the child classes
nzb =
  Connection: require('./connection').Connection
  Decoder: require('./decoder').Decoder
  Downloader: require('./downloader').Downloader
  Parser: require('./parser').Parser
  Pool: require('./pool').Pool

for prop, value of nzb
  exports[prop] = value

# Export a singleton downloader
downloader = new nzb.Downloader
for method of ['add','configure','move','remove','status']
  exports[method] = -> downloader[method].apply(arguments)
