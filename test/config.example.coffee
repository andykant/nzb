# server for normal connection testing
exports.normal =
  host: 'news.example.com'
  port: 119
  secure: no
  username: 'username'
  password: 'password'
  connections: 1

# server for secure connection testing
exports.secure =
  host: 'secure.example.com'
  port: 563
  secure: yes
  username: 'username'
  password: 'password'
  connections: 1

# server for connection pool testing
exports.pool =
  host: 'secure.example.com'
  port: 563
  secure: yes
  username: 'username'
  password: 'password'
  connections: 4
