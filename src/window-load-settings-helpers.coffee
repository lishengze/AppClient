remote = require 'remote'
_ = require 'underscore-plus'

windowLoadSettings = null

exports.getWindowLoadSettings = ->
  windowLoadSettings ?= JSON.parse(window.decodeURIComponent(window.location.hash.substr(1)))
  clone = _.deepClone(windowLoadSettings)

  # The windowLoadSettings.windowState could be large, request it only when needed.
  clone.__defineGetter__ 'windowState', ->
    remote.getCurrentWindow().loadSettings.windowState
  clone.__defineSetter__ 'windowState', (value) ->
    remote.getCurrentWindow().loadSettings.windowState = value

  clone

exports.setWindowLoadSettings = (settings) ->
  console.log 'windowLoadSettings: '
  console.log windowLoadSettings
  console.log location
  windowLoadSettings = settings
  location.hash = encodeURIComponent(JSON.stringify(settings))
