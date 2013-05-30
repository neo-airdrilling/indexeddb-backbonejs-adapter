class IndexedDBBackbone.Driver.Operation
  mode: IndexedDBBackbone.IDBTransaction.READ_ONLY

  constructor: (@db, storeName, @data, @options = {}) ->
    @transaction = @_transaction(storeName)
    @store = @transaction.objectStore(storeName)

    @exclusiveTransaction = !@options.transaction

  _transaction: (storeName) ->
    @options.transaction || @db.transaction([storeName], @mode)

  execute: ->

class IndexedDBBackbone.Driver.AddOperation extends IndexedDBBackbone.Driver.Operation
  mode: IndexedDBBackbone.IDBTransaction.READ_WRITE

  execute: ->
    if @store.keyPath || @store.autoIncrement
      request = @store.add(@data)
    else
      request = @store.add(@data, @options.key)

    if @exclusiveTransaction
      if @store.keyPath
        request.onsuccess = (e) => @data[@store.keyPath] = e.target.result
      @transaction.onerror = @options.error
      if @options.success
        @transaction.oncomplete = (e) => @options.success(@data)
    else
      request.onerror = @options.error
      request.onsuccess = (e) =>
        @data[@store.keyPath] = e.target.result if @store.keyPath
        @options.success?(@data)


class IndexedDBBackbone.Driver.PutOperation extends IndexedDBBackbone.Driver.Operation
  mode: IndexedDBBackbone.IDBTransaction.READ_WRITE

  execute: ->
    # acts as insert & update
    if @store.keyPath || (@store.autoIncrement && !@options.key)
      request = @store.put(@data)
    else
      request = @store.put(@data, @options.key)

    if @exclusiveTransaction
      @transaction.onerror = @options.error
      if @options.success
        @transaction.oncomplete = (e) => @options.success(@data)
    else
      request.onerror = @options.error
      if @options.success
        request.onsuccess = (e) => @options.success(@data)

class IndexedDBBackbone.Driver.DeleteOperation extends IndexedDBBackbone.Driver.Operation
  mode: IndexedDBBackbone.IDBTransaction.READ_WRITE

  execute: ->
    request = @store.delete(@data)

    if @exclusiveTransaction
      @transaction.onerror = @options.error
      if @options.success
        @transaction.oncomplete = (e) => @options.success(@data)
    else
      request.onerror = @options.error
      if @options.success
        request.onsuccess = (e) => @options.success(@data)

class IndexedDBBackbone.Driver.ClearOperation extends IndexedDBBackbone.Driver.Operation
  mode: IndexedDBBackbone.IDBTransaction.READ_WRITE

  constructor: (db, storeName, options) ->
    super db, storeName, null, options

  execute: ->
    request = @store.clear()

    if @exclusiveTransaction
      @transaction.oncomplete = @options.success
      @transaction.onerror = @options.error
    else
      request.onsuccess = @options.success
      request.onerror = @options.error

class IndexedDBBackbone.Driver.GetOperation extends IndexedDBBackbone.Driver.Operation
  execute: ->
    if @store.keyPath && value = IndexedDBBackbone.value(@data, @store.keyPath)
      getRequest = @store.get(value)
    else if indexName = @options.indexName
      index = @store.index(indexName)
      keyPath = index.keyPath
      value = IndexedDBBackbone.value(@data, keyPath)
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

class IndexedDBBackbone.Driver.Query extends IndexedDBBackbone.Driver.Operation
  constructor: (db, storeName, options) ->
    super db, storeName, null, options

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

