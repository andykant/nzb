# This is an example test configuration.
# - Make a copy of this file
# - Customize the server settings
# - Save as config.coffee

module.exports =
  # server for normal/insecure connection testing
  normal:
    host: 'news.example.com'
    port: 119
    secure: no
    username: 'username'
    password: 'password'
    connections: 1
  # server for secure connection testing
  secure: 
    host: 'secure.example.com'
    port: 563
    secure: yes
    username: 'username'
    password: 'password'
    connections: 1
  # server for connection pool testing
  pool:
    host: 'secure.example.com'
    port: 563
    secure: yes
    username: 'username'
    password: 'password'
    connections: 4
