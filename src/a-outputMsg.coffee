ipc = require 'ipc'

ipc.on 'hello', (data) ->
  console.log data
