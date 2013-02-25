IndexedDBBackbone.transaction = (objects, callback, options={}) ->
  indexedDB = IndexedDBBackbone.indexedDB

  options.callback = callback
  IndexedDBBackbone.sync 'begin', objects, options

Backbone.transaction = IndexedDBBackbone.transaction

