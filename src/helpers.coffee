IndexedDBBackbone =
  value: (object, key) ->
    _.reduce key.split('.'), ((obj, key) -> obj?[key]), object

  getLogger: (channel) ->
    if channel
      if window?.console?[channel]?
        window.console[channel].bind(window.console)
      else if console?[channel]?
        console[channel].bind(console)
    else
      ->

if typeof exports != 'undefined'
  window._ = require('underscore')
  window.Backbone = require('backbone')
else
  window.IndexedDBBackbone = IndexedDBBackbone

