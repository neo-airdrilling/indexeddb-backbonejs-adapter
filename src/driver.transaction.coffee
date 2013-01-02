class IndexedDBBackbone.Driver extends IndexedDBBackbone.Driver

  begin: (storeNames) ->
    @execute =>
      @_transaction = @db.transaction(storeNames, IndexedDBBackbone.IDBTransaction.READ_WRITE)

  commit: ->
    @execute =>
      @_transaction = null

  abort: ->
    @execute =>
      @_transaction.abort()
      @_transaction = null

  create: (storeNames, object, options) ->
    @execute =>
      transaction = @transaction(storeNames, IndexedDBBackbone.IDBTransaction.READ_WRITE)
      request = new IndexedDBBackbone.Driver.AddRequest(transaction, storeNames, object.toJSON(), options)
      request.execute()

  read: (storeNames, object, options) ->
    @execute =>
      if object.id || object.cid
        transaction = @transaction(storeNames)
        request = new IndexedDBBackbone.Driver.GetRequest(transaction, storeNames, object.toJSON(), options)
        request.execute()
      else
        @query(storeNames, object, options)

  update: (storeNames, object, options) ->
    @execute =>
      transaction = @transaction(storeNames, IndexedDBBackbone.IDBTransaction.READ_WRITE)
      request = new IndexedDBBackbone.Driver.PutRequest(transaction, storeNames, object.toJSON(), options)
      request.execute()

  delete: (storeNames, object, options) ->
    @execute =>
      transaction = @transaction(storeNames, IndexedDBBackbone.IDBTransaction.READ_WRITE)
      if object.id || object.cid
        request = new IndexedDBBackbone.Driver.DeleteRequest(transaction, storeNames, object.toJSON(), options)
      else
        request = new IndexedDBBackbone.Driver.ClearRequest(transaction, storeNames, object.toJSON(), options)
      request.execute()

  transaction: (storeNames, mode = IndexedDBBackbone.IDBTransaction.READ_ONLY) ->
    @_transaction || @db.transaction(storeNames, mode)

  # Performs a query on storeName in db.
  # options may include :
  # - conditions : value of an index, or range for an index
  # - range : range for the primary key
  # - limit : max number of elements to be yielded
  # - offset : skipped items.
  query: (storeName, collection, options) ->
    elements = []
    skipped = 0
    processed = 0
    queryTransaction = this.db.transaction([storeName], "readonly")
    #@_track_transaction(queryTransaction)

    readCursor = null
    store = queryTransaction.objectStore(storeName)
    index = null
    lower = null
    upper = null
    bounds = null

    if (options.conditions)
      # We have a condition, we need to use it for the cursor
      _.each store.indexNames, (key) ->
        if (!readCursor)
          index = store.index(key)
          if (options.conditions[index.keyPath] instanceof Array)
            lower = if options.conditions[index.keyPath][0] > options.conditions[index.keyPath][1] then options.conditions[index.keyPath][1] else options.conditions[index.keyPath][0]
            upper = if options.conditions[index.keyPath][0] > options.conditions[index.keyPath][1] then options.conditions[index.keyPath][0] else options.conditions[index.keyPath][1]
            bounds = IndexedDBBackbone.IDBKeyRange.bound(lower, upper, true, true)

            if (options.conditions[index.keyPath][0] > options.conditions[index.keyPath][1])
              # Looks like we want the DESC order
              readCursor = index.openCursor(bounds, IndexedDBBackbone.IDBCursor.PREV || "prev")
            else
              # We want ASC order
              readCursor = index.openCursor(bounds, IndexedDBBackbone.IDBCursor.NEXT || "next")
          else if (options.conditions[index.keyPath] != undefined)
            bounds = IndexedDBBackbone.IDBKeyRange.only(options.conditions[index.keyPath])
            readCursor = index.openCursor(bounds)
    else
      # No conditions, use the index
      if (options.range)
        lower = if options.range[0] > options.range[1] then options.range[1] else options.range[0]
        upper = if options.range[0] > options.range[1] then options.range[0] else options.range[1]
        bounds = IndexedDBBackbone.IDBKeyRange.bound(lower, upper)
        if (options.range[0] > options.range[1])
          readCursor = store.openCursor(bounds, IndexedDBBackbone.IDBCursor.PREV || "prev")
        else
          readCursor = store.openCursor(bounds, IndexedDBBackbone.IDBCursor.NEXT || "next")
      else
        readCursor = store.openCursor()

    if (typeof (readCursor) == "undefined" || !readCursor)
      options.error("No Cursor")
    else
      readCursor.onerror = (e) ->
        options.error("readCursor error", e)
      # Setup a handler for the cursor’s `success` event:
      readCursor.onsuccess = (e) ->
        cursor = e.target.result
        if (!cursor)
          if (options.addIndividually || options.clear)
            # nothing!
            # We need to indicate that we're done. But, how?
            collection.trigger("reset")
          else
            options.success(elements) # We're done. No more elements.
        else
          # Cursor is not over yet.
          if (options.limit && processed >= options.limit)
            # Yet, we have processed enough elements. So, let's just skip.
            if (bounds && options.conditions[index.keyPath])
              cursor.continue(options.conditions[index.keyPath][1] + 1) # We need to 'terminate' the cursor cleany, by moving to the end */
            else
              cursor.continue() # We need to 'terminate' the cursor cleany, by moving to the end */
          else if (options.offset && options.offset > skipped)
            skipped++
            cursor.continue() # We need to Moving the cursor forward
          else
            # This time, it looks like it's good!
            if (options.addIndividually)
              collection.add(cursor.value)
            else if (options.clear)
              deleteRequest = store.delete(cursor.value.id)
              deleteRequest.onsuccess = (event) ->
                elements.push(cursor.value)
              deleteRequest.onerror = (event) ->
                elements.push(cursor.value)
            else
              elements.push(cursor.value)
            processed++
            cursor.continue()

