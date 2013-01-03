IndexedDBBackbone.transaction = (objects, callback, options) ->
  indexedDB = IndexedDBBackbone.indexedDB

  IndexedDBBackbone.sync 'begin', objects, options
  try
    if callback()
      IndexedDBBackbone.sync 'commit', objects
    else
      IndexedDBBackbone.sync 'abort', objects
  catch error
    IndexedDBBackbone.sync 'abort', objects
    options?.error?(error)

Backbone.transaction = IndexedDBBackbone.transaction

