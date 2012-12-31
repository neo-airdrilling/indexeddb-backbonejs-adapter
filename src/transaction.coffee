IndexedDBBackbone.transaction = (objects, callback) ->
  indexedDB = IndexedDBBackbone.indexedDB

  IndexedDBBackbone.sync 'begin', objects
  try
    if callback()
      IndexedDBBackbone.sync 'commit', objects
    else
      IndexedDBBackbone.sync 'abort', objects
  catch error
    console.error "Error in transaction, rolling back:", error
    IndexedDBBackbone.sync 'abort', objects

Backbone.transaction = IndexedDBBackbone.transaction

