# Like sands through the hourglass, so are the days of our lives.
module.exports = ({blobStore}) ->
  path = require 'path'
  require './window'
  {getWindowLoadSettings} = require './window-load-settings-helpers'

  {resourcePath, isSpec, devMode} = getWindowLoadSettings()

  # Add application-specific exports to module search path.
  exportsPath = path.join(resourcePath, 'exports')
  require('module').globalPaths.push(exportsPath)
  process.env.NODE_PATH = exportsPath

  # Make React faster
  process.env.NODE_ENV ?= 'production' unless devMode

  AtomEnvironment = require './atom-environment'  # 初始化环境; 对外提供接口， 非常重要.https://atom.io/docs/api/v1.7.1/AtomEnvironment
  ApplicationDelegate = require './application-delegate'
  window.atom = new AtomEnvironment({
    window, document, blobStore,
    applicationDelegate: new ApplicationDelegate,  # 应用代表， 渲染进程向主进程发送消息;
    configDirPath: process.env.ATOM_HOME
    enablePersistence: true
  })

  atom.displayWindow()     # window 全局对象;
  atom.startEditorWindow() # 启动的过程;

  # Workaround for focus getting cleared upon window creation
  windowFocused = ->
    window.removeEventListener('focus', windowFocused)
    setTimeout (-> document.querySelector('atom-workspace').focus()), 0
  window.addEventListener('focus', windowFocused)
