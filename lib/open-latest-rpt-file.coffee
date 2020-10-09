fs = require 'fs'
path = require 'path'
process = require 'process'

module.exports =
  getLatestRptFile: (dir) ->
    (fs.readdirSync dir
      .filter (v) ->
        '.rpt' == path.extname (v)
      .map (v) ->
        return {
          name: dir+v,
          time: fs.statSync(dir + v).mtime.getTime()}
      .sort (a, b) -> b.time - a.time
      .map (v) -> v.name)[0]

  open: ->
    p = atom.config.get('language-arma-atom-continued.appDataFolder').replace /%([^%]+)%/g, (_,n) -> process.env[n]
    atom.workspace.open(@getLatestRptFile p).then (rptView) ->
      rptView.moveToBottom()
      rptView.getElement().scrollToBottom()
      rptView.getBuffer().onDidReload (e) ->
        rptView.moveToBottom()
        rptView.getElement().scrollToBottom()
