# Generate four random hex digits.
window.S4 = ->
  (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1)

# Generate a pseudo-GUID by concatenating random hexadecimal.
window.guid = ->
  (S4() + S4() + "-" + S4() + "-" + S4() + "-" + S4() + "-" + S4() + S4() + S4())


window.debugLog = ->
  if typeof window != "undefined" && typeof window.console != "undefined" && typeof window.console.log != "undefined"
    window.console.log.apply window.console, arguments
  else if console.log != "undefined"
    console.log.apply console, arguments

if typeof exports != 'undefined'
  window._ = require('underscore')
  window.Backbone = require('backbone')

