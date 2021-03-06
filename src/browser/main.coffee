global.shellStartTime = Date.now() # 性能检测,启动花的时间;

process.on 'uncaughtException', (error={}) ->
  console.log(error.message) if error.message?
  console.log(error.stack) if error.stack?


crashReporter = require 'crash-reporter'  # electron 的模块, 用于向服务器发送信息， api 在electron:
app = require 'app'                       # electron;
fs = require 'fs-plus'
path = require 'path'
yargs = require 'yargs'
console.log = require 'nslog'

start = ->
  args = parseCommandLine()
  setupAtomHome(args)
  setupCompileCache()
  return if handleStartupEventWithSquirrel() # 负责自动更新;

  # NB: This prevents Win10 from showing dupe items in the taskbar
  app.setAppUserModelId('com.squirrel.monitor.monitor')

  app.on 'will-finish-launching', setupCrashReporter

  app.on 'ready', ->
    AtomApplication = require path.join(args.resourcePath, 'src', 'browser', 'atom-application')  # 管理所有的功能;
    AtomApplication.open(args) # atom-application 根据参数执行操作;
    console.log 'Test-0.1.2'
    console.log("App load time: #{Date.now() - global.shellStartTime}ms") unless args.test  #显示启动时间;

normalizeDriveLetterName = (filePath) ->
  if process.platform is 'win32'
    filePath.replace /^([a-z]):/, ([driveLetter]) -> driveLetter.toUpperCase() + ":"
  else
    filePath

handleStartupEventWithSquirrel = ->
  return false unless process.platform is 'win32' # 目前的自动更新只支持win32;
  SquirrelUpdate = require './squirrel-update'    # 负责自动更新;
  squirrelCommand = process.argv[1]
  SquirrelUpdate.handleStartupEvent(app, squirrelCommand)

setupCrashReporter = ->
  crashReporter.start(productName: '慧眼监控', companyName: 'SFIT', submitUrl: 'tbd') # 启动监听crash的服务;

setupAtomHome = ({setPortable}) ->
  return if process.env.ATOM_HOME

  #=> 改变用户数据目录, 创建用户的monitor
  atomHome = path.join(app.getHomeDir(), '.monitor')

  AtomPortable = require './atom-portable'


  if setPortable and not AtomPortable.isPortableInstall(process.platform, process.env.ATOM_HOME, atomHome)
    try
      AtomPortable.setPortable(atomHome)
    catch error
      console.log("Failed copying portable directory '#{atomHome}' to '#{AtomPortable.getPortableAtomHomePath()}'")
      console.log("#{error.message} #{error.stack}")

  if AtomPortable.isPortableInstall(process.platform, process.env.ATOM_HOME, atomHome)
    atomHome = AtomPortable.getPortableAtomHomePath()

  try
    atomHome = fs.realpathSync(atomHome)

  # 进程的用户目录;
  process.env.ATOM_HOME = atomHome

# 编译时产生的缓存， 将 coffee编译成 js 的缓存;
setupCompileCache = ->
  compileCache = require('../compile-cache')
  compileCache.setAtomHomeDirectory(process.env.ATOM_HOME)

#解析命令行like: atom --version;
parseCommandLine = ->
  version = app.getVersion()
  options = yargs(process.argv[1..]).wrap(100) # note1
  #=> 改变命令行的使用帮助
  options.usage """
    慧眼监控 v#{version}

    使用: monitor [options]
  """
  options.alias('h', 'help').boolean('h').describe('h', '使用手册')
  options.alias('v', 'version').boolean('v').describe('v', '版本')

  # options.usage """
  #   Atom Editor v#{version}
  #
  #   Usage: atom [options] [path ...]
  #
  #   One or more paths to files or folders may be specified. If there is an
  #   existing Atom window that contains all of the given folders, the paths
  #   will be opened in that window. Otherwise, they will be opened in a new
  #   window.
  #
  #   Environment Variables:
  #
  #     ATOM_DEV_RESOURCE_PATH  The path from which Atom loads source code in dev mode.
  #                             Defaults to `~/github/atom`.
  #
  #     ATOM_HOME               The root path for all configuration files and folders.
  #                             Defaults to `~/.atom`.
  # """
  # Deprecated 1.0 API preview flag
  # options.alias('1', 'one').boolean('1').describe('1', 'This option is no longer supported.')
  # options.boolean('include-deprecated-apis').describe('include-deprecated-apis', 'This option is not currently supported.')
  # options.alias('d', 'dev').boolean('d').describe('d', 'Run in development mode.')
  # options.alias('f', 'foreground').boolean('f').describe('f', 'Keep the browser process in the foreground.')
  # options.alias('h', 'help').boolean('h').describe('h', 'Print this usage message.')
  # options.alias('l', 'log-file').string('l').describe('l', 'Log all output to file.')
  # options.alias('n', 'new-window').boolean('n').describe('n', 'Open a new window.')
  # options.boolean('profile-startup').describe('profile-startup', 'Create a profile of the startup execution time.')
  # options.alias('r', 'resource-path').string('r').describe('r', 'Set the path to the Atom source directory and enable dev-mode.')
  # options.boolean('safe').describe('safe', 'Do not load packages from ~/.atom/packages or ~/.atom/dev/packages.')
  # options.boolean('portable').describe('portable', 'Set portable mode. Copies the ~/.atom folder to be a sibling of the installed Atom location if a .atom folder is not already there.')
  # options.alias('t', 'test').boolean('t').describe('t', 'Run the specified specs and exit with error code on failures.')
  # options.string('timeout').describe('timeout', 'When in test mode, waits until the specified time (in minutes) and kills the process (exit code: 130).')
  # options.alias('v', 'version').boolean('v').describe('v', 'Print the version.')
  # options.alias('w', 'wait').boolean('w').describe('w', 'Wait for window to be closed before returning.')
  # options.string('socket-path')

  args = options.argv

  if args.help
    process.stdout.write(options.help())
    process.exit(0)

  if args.version
    process.stdout.write("#{version}\n")
    process.exit(0)

  executedFrom = args['executed-from']?.toString() ? process.cwd()
  devMode = args['dev']
  safeMode = args['safe']
  pathsToOpen = args._
  test = args['test']
  timeout = args['timeout']
  newWindow = args['new-window']
  pidToKillWhenClosed = args['pid'] if args['wait']
  logFile = args['log-file']
  socketPath = args['socket-path']
  profileStartup = args['profile-startup']
  urlsToOpen = []
  devResourcePath = process.env.ATOM_DEV_RESOURCE_PATH ? path.join(app.getHomeDir(), 'github', 'atom')
  setPortable = args.portable

  if args['resource-path']
    devMode = true
    resourcePath = args['resource-path']

  devMode = true if test
  resourcePath ?= devResourcePath if devMode

  unless fs.statSyncNoException(resourcePath)
    resourcePath = path.dirname(path.dirname(__dirname))

  # On Yosemite the $PATH is not inherited by the "open" command, so we have to
  # explicitly pass it by command line, see http://git.io/YC8_Ew.
  process.env.PATH = args['path-environment'] if args['path-environment']

  resourcePath = normalizeDriveLetterName(resourcePath)
  devResourcePath = normalizeDriveLetterName(devResourcePath)

  originArgs = {resourcePath, devResourcePath, pathsToOpen, urlsToOpen, executedFrom, test,
   version, pidToKillWhenClosed, devMode, safeMode, newWindow,
   logFile, socketPath, profileStartup, timeout, setPortable}

  #=> 禁用其他选项，只允许正常模式的使用
  # resourcePath = path.dirname(path.dirname(__dirname))
  # pathsToOpen = []
  # urlsToOpen = []
  # test = false
  # pidToKillWhenClosed = undefined
  # devMode = false
  # safeMode = false
  # newWindow = false
  # logFile = undefined
  # socketPath = undefined
  # profileStartup = false
  # timeout = undefined
  # setPortable = false
  modifiedArgs =
    {
      resourcePath: path.dirname(path.dirname(__dirname)),
      devResourcePath: '',
      pathsToOpen: [],
      urlsToOpen: [],
      executedFrom: '',
      test: false,
      version: version,
      pidToKillWhenClosed: undefined,
      devMode: false,
      safeMode: false,
      newWindow: false,
      logFile: undefined,
      socketPath: undefined,
      profileStartup: false,
      timeout: undefined,
      setPortable: false
    }
  # modifiedArgs = {resourcePath, devResourcePath, pathsToOpen, urlsToOpen, executedFrom, test,
  #  version, pidToKillWhenClosed, devMode, safeMode, newWindow,
  #  logFile, socketPath, profileStartup, timeout, setPortable}

  # fs.writeFile('c:\\Users\\yyc\\originArgs.txt', JSON.stringify(originArgs))
  # fs.writeFile('c:\\Users\\yyc\\modifiedArgs.txt', JSON.stringify(modifiedArgs))

  modifiedArgs
  # originArgs

start()
