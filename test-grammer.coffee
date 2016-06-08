# path = require 'path'
# fs = require 'fs-plus'
#
# console.log __dirname
# fileName = path.resolve(__dirname, 'message.txt')
# console.log fileName
#
# fileName = 'D:\\Document\\github\\monitor-client\\M3\\message.txt'
# console.log fileName
#
# outputData = (data) ->
#   #fileName = path.resolve(__dirname, 'message.txt')
#   fileName = 'message.txt'
#   fs.appendFile fileName, data, (err) ->
#     console.log 'The data to append was appended to file!'
# numb = 10
# outputData '1 ' + numb.toString() + '\n'
# outputData '1 ' + '\n'
# outputData '1 ' + '\n'
# outputData '1 ' + '\n'

packageJson = require '../package.json'
console.log packageJson.version
