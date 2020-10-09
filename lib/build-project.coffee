spawn = require('child_process').spawn
p = require('path')

module.exports =
  getProjectPath: ->
    ref = atom.project.getDirectories()
    editor = atom.workspace.getActiveTextEditor()
    projectPath = ''
    if editor
      currentFile = p.dirname editor.getPath()
      i = 0
      len = ref.length;
      while i < len
        directory = ref[i];
        if currentFile.includes directory.path
            projectPath = directory.path;
            i = len
        i++
    path: projectPath

  build: (type, text, script) ->
    # Start notification
    startNotification = atom.notifications.addInfo (text + ' Build Started'), dismissable: true, detail: 'Stand by ...'

    # Get Script Path
    path = atom.config.get('language-arma-atom-continued.build' + type + 'Script')
    if /<current-project>/.test(path)
      path = @getProjectPath().path + '\\tools\\' + script

    # Spawn build process and add Error notification handler
    buildProcess = spawn 'python', [path.replace(/%([^%]+)%/g, (_,n) -> process.env[n])]
    buildProcess.stderr.on 'data', (data) -> atom.notifications.addError (text + ' Build Error'), dismissable: true, detail: data

    buildProcess: buildProcess
    startNotification: startNotification

  dev: ->
    info = @build("Dev", "Development", "build.py")

    # Add Success notification handler
    info.buildProcess.stdout.on 'data', (data) -> atom.notifications.addSuccess 'Development Build Passed', dismissable: true, detail: data

    # Hide start notification
    info.buildProcess.stdout.on 'close', => info.startNotification.dismiss()

  release: ->
    info = @build("Release", "Release", "make.py")

    # Add Info notification handler
    info.buildProcess.stdout.on 'data', (data) -> atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: data

    # Hide start notification, check output to determine if finished as make.py does not close automatically
    info.buildProcess.stdout.on 'data', (data) ->
      if /Press Enter to continue.../.test(data)
        info.startNotification.dismiss()
        # Display final Success notification as notificatons from make.py get splitted for some reason
        atom.notifications.addSuccess 'Release Build Passed', dismissable: true, detail: 'Release build finished successfully, refer to above progress/error notifications for more information.'

  hemtt_build: (type, text, release, force) ->
    # Start notification
    startNotification = atom.notifications.addInfo ('HEMTT ' + text + ' Build Started'), dismissable: true, detail: 'Stand by ...'
    # Spawn build process and add Error notification handler
    parameters = ['build', '--ci']
    if release
      parameters.push '--release'
    if force
      parameters.push '--force'
    buildProcess = spawn 'hemtt', parameters, {cwd: @getProjectPath().path}
    buildProcess.stderr.on 'data', (data) -> atom.notifications.addError (text + ' Build Error'), dismissable: true, detail: data

    buildProcess: buildProcess
    startNotification: startNotification

  hemtt_release: ->
    info = @hemtt_build("Release", "Release", true, false)
    alldata = "";
    # Add Info notification handler
    updateNotification = null
    info.buildProcess.stdout.on 'data', (data) ->
      alldata += data
      if updateNotification
        updateNotification.dismiss()
      updateNotification = atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: data


    # Hide start notification, check output to determine if finished as make.py does not close automatically
    info.buildProcess.on 'exit', (err) ->
      info.startNotification.dismiss()
      atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: alldata
      if !err
        # Display final Success notification as notificatons from make.py get splitted for some reason
        updateNotification = atom.notifications.addSuccess 'Release Build Passed', dismissable: true, detail: 'Release build finished successfully, refer to above progress/error notifications for more information.'

  hemtt_dev: ->
    info = @hemtt_build("Dev", "Development", false, false)
    alldata = "";
    # Add Info notification handler
    updateNotification = null
    info.buildProcess.stdout.on 'data', (data) ->
      alldata += data
      if updateNotification
        updateNotification.dismiss()
      updateNotification = atom.notifications.addInfo 'Development Build Progress', dismissable: true, detail: data

    # Hide start notification, check output to determine if finished as make.py does not close automatically
    info.buildProcess.on 'exit', (err) ->
      info.startNotification.dismiss()
      atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: alldata
      if !err
        # Display final Success notification as notificatons from make.py get splitted for some reason
        atom.notifications.addSuccess 'Development Build Passed', dismissable: true, detail: 'Development build finished successfully, refer to above progress/error notifications for more information.'

  hemtt_release_force: ->
    info = @hemtt_build("Release", "Release", true, true)
    alldata = "";
    # Add Info notification handler
    info.buildProcess.stdout.on 'data', (data) ->
      alldata += data
      if updateNotification
        updateNotification.dismiss()
      updateNotification = atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: data

    # Hide start notification, check output to determine if finished as make.py does not close automatically
    info.buildProcess.on 'exit', (err) ->
      info.startNotification.dismiss()
      atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: alldata
      if !err
        # Display final Success notification as notificatons from make.py get splitted for some reason
        atom.notifications.addSuccess 'Release Build Passed', dismissable: true, detail: 'Release build finished successfully, refer to above progress/error notifications for more information.'

  hemtt_dev_force: ->
    info = @hemtt_build("Dev", "Development", false, true)
    alldata = "";
    # Add Info notification handler
    info.buildProcess.stdout.on 'data', (data) ->
      alldata += data
      if updateNotification
        updateNotification.dismiss()
      updateNotification = atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: data

    # Hide start notification, check output to determine if finished as make.py does not close automatically
    info.buildProcess.on 'exit', (err) ->
      info.startNotification.dismiss()
      atom.notifications.addInfo 'Release Build Progress', dismissable: true, detail: alldata
      if !err
        # Display final Success notification as notificatons from make.py get splitted for some reason
        atom.notifications.addSuccess 'Development Build Passed', dismissable: true, detail: 'Development build finished successfully, refer to above progress/error notifications for more information.'
