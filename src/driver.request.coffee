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

    request.onerror = @options.error
    if @options.success
      request.onsuccess = (e) => @options.success(@objectJSON)

class IndexedDBBackbone.Driver.ClearRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    request = @store.clear()
    request.onsuccess = @options.success
    request.onerror = @options.error

class IndexedDBBackbone.Driver.GetRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    if @objectJSON.id
      getRequest = @store.get(@objectJSON.id)
    else if indexName = @options.indexName
      index = @store.index(indexName)
      keyPath = index.keyPath
      value = _.reduce keyPath.split('.'), ((obj, key) -> obj?[key]), @objectJSON
      getRequest = index.get(value) if value

    if (getRequest)
      getRequest.onsuccess = (e) =>
        if (e.target.result)
          @options.success?(e.target.result)
        else
          @options.error?("Not Found")
      getRequest.onerror = @options.error
    else
      @options.error?("Couldn't search: no index matches the provided model data")

class IndexedDBBackbone.Driver.Query extends IndexedDBBackbone.Driver.Request
  execute: ->
    options = @options
    query = options.query

    elements = []
    needsAdvancement = query._offset > 0

    source = if query._indexName then @store.index(query._indexName) else @store
    range = query.getKeyRange()

    cursorRequest = source.openCursor range, query.getDirection()

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

