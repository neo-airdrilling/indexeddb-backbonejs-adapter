class IndexedDBBackbone.Driver.Request
  constructor: (transaction, storeName, objectJSON, options) ->
    @objectJSON = objectJSON
    @options = options

    @store = transaction.objectStore(storeName)

  execute: ->
    request = @run()
    @bindCallbacks(request)

  bindCallbacks: (request) ->
    request.onerror = (e) =>
      @options.error(e)
    request.onsuccess = (e) =>
      @options.success(@objectJSON)

class IndexedDBBackbone.Driver.AddRequest extends IndexedDBBackbone.Driver.Request
  run: ->
    if (@objectJSON.id == undefined) then @objectJSON.id = guid()
    if (@objectJSON.id == null) then delete @objectJSON.id

    if @store.keyPath then @store.add(@objectJSON) else @store.add(@objectJSON, @objectJSON.id)

class IndexedDBBackbone.Driver.PutRequest extends IndexedDBBackbone.Driver.Request
  run: ->
    @objectJSON.id = guid() unless @objectJSON.id?

    if @store.keyPath then @store.put(@objectJSON) else @store.put(@objectJSON, @objectJSON.id)

class IndexedDBBackbone.Driver.DeleteRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    request = @store.delete(@objectJSON.id)
    request.onsuccess = (event) =>
      @options.success(null)
    request.onerror = (event) =>
      @options.error("Not Deleted")

class IndexedDBBackbone.Driver.ClearRequest extends IndexedDBBackbone.Driver.Request
  execute: ->
    request = @store.clear()
    request.onsuccess = (e) =>
      @options.success(null)
    request.onerror = (e) =>
      @options.error("Not Cleared")

class IndexedDBBackbone.Driver.GetRequest extends IndexedDBBackbone.Driver.Request
  execute: -> #this doesn't have to call bindCallbacks because it's different
    if (@objectJSON.id)
      getRequest = @store.get(@objectJSON.id)
    else
      _.each @store.indexNames, (key, index) =>
        index = @store.index(key)
        if @objectJSON[index.keyPath]
          getRequest = index.get(@objectJSON[index.keyPath])

    if (getRequest)
      getRequest.onsuccess = (e) =>
        if (e.target.result)
          @options.success(e.target.result)
        else
          @options.error("Not Found")
      getRequest.onerror = () =>
        @options.error("Not Found") # We couldn't find the record.
    else
      @options.error("Not Found") # We couldn't even look for it, as we don't have enough data.

class IndexedDBBackbone.Driver.Query extends IndexedDBBackbone.Driver.Request

