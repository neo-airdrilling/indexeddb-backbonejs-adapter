class IndexedDBBackbone.Driver.Request
  constructor: (transaction, storeName, objectJSON, options) ->
    @objectJSON = objectJSON
    @options = options || {}

    @store = transaction.objectStore(storeName)

  execute: ->

class IndexedDBBackbone.Driver.AddRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    if (@objectJSON.id == undefined) then @objectJSON.id = IndexedDBBackbone.guid()
    if (@objectJSON.id == null) then delete @objectJSON.id

    request = if @store.keyPath then @store.add(@objectJSON) else @store.add(@objectJSON, @objectJSON.id)

    request.onerror = @options.error
    if @options.success
      request.onsuccess = (e) => @options.success(@objectJSON)

class IndexedDBBackbone.Driver.PutRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    @objectJSON.id = IndexedDBBackbone.guid() unless @objectJSON.id?

    request = if @store.keyPath then @store.put(@objectJSON) else @store.put(@objectJSON, @objectJSON.id)

    request.onerror = @options.error
    if @options.success
      request.onsuccess = (e) => @options.success(@objectJSON)

class IndexedDBBackbone.Driver.DeleteRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    request = @store.delete(@objectJSON.id)
    request.onsuccess = (e) => @options.success(@objectJSON)
    request.onerror = @options.error

class IndexedDBBackbone.Driver.ClearRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    request = @store.clear()
    request.onsuccess = @options.success
    request.onerror = @options.error

class IndexedDBBackbone.Driver.GetRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    if (@objectJSON.id)
      getRequest = @store.get(@objectJSON.id)
    else
      _.each @store.indexNames, (key, index) =>
        index = @store.index(key)
        if @objectJSON[index.keyPath] # FIXME: Doesn't work with nested paths. e.g. "foo.bar"
          getRequest = index.get(@objectJSON[index.keyPath])

    if (getRequest)
      getRequest.onsuccess = (e) =>
        if (e.target.result) # TODO: handle many results on non-unique index?
          @options.success?(e.target.result)
        else
          @options.error?("Not Found") # TODO: when does this happen...
      getRequest.onerror = @options.error # ...as opposed to this?
    else
      @options.error?("Couldn't search: no index matches the provided model data")

class IndexedDBBackbone.Driver.Query extends IndexedDBBackbone.Driver.Request
  execute: ->
    options = @options
    query = options.query

    elements = []
    needsAdvancement = query._offset > 0

    source = if query._indexName then @store.index(query._indexName) else @store
    bounds = null

    if query._only
      bounds = IndexedDBBackbone.IDBKeyRange.only(query._only)
    else if query._lower || query._upper
      bounds = IndexedDBBackbone.IDBKeyRange.bound query._lower, query._upper, query._lowerOpen, query._upperOpen

    cursorRequest = source.openCursor bounds, query.getDirection()

    cursorRequest.onerror = (e) ->
      options.error("cursorRequest error", e)

    cursorRequest.onsuccess = (e) ->
      if cursor = e.target.result
        if (needsAdvancement)
          needsAdvancement = false
          cursor.advance(query._offset)
        else
          elements.push(cursor.value)
          if (query._limit && elements.length >= query._limit)
            options.success?(elements) # We're done.
          else
            cursor.continue()
      else
        options.success?(elements) # We're done. No more elements.

