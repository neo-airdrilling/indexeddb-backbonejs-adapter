class IndexedDBBackbone.Driver extends IndexedDBBackbone.Driver
  # Tracks transactions. Mostly for debugging purposes. TO-IMPROVE
  _track_transaction: (transaction) ->
    @transactions.push(transaction)
    removeIt = =>
      idx = @transactions.indexOf(transaction)
      if (idx != -1)
        @transactions.splice(idx)
    transaction.oncomplete = removeIt
    transaction.onabort = removeIt
    transaction.onerror = removeIt

  # This is the main method, called by the ExecutionQueue when the driver is ready (database open and migration performed)
  execute: (storeName, method, object, options) ->
    @logger("execute : " + method +  " on " + storeName + " for " + object.id)
    switch method
      when "create"
        transaction = @db.transaction([storeName], 'readwrite')
        request = new IndexedDBBackbone.Driver.AddRequest(transaction, storeName, object.toJSON(), options)
      when "read"
        if object.id || object.cid
          transaction = @db.transaction([storeName], "readonly")
          request = new IndexedDBBackbone.Driver.GetRequest(transaction, storeName, object.toJSON(), options)
        else
          @query(storeName, object, options) # It's a collection
      when "update" # We may want to check that this is not a collection. TOFIX
        transaction = @db.transaction([storeName], 'readwrite')
        request = new IndexedDBBackbone.Driver.PutRequest(transaction, storeName, object.toJSON(), options)
      when "delete"
        transaction = @db.transaction([storeName], 'readwrite')
        if object.id || object.cid
          request = new IndexedDBBackbone.Driver.DeleteRequest(transaction, storeName, object.toJSON(), options)
        else
          request = new IndexedDBBackbone.Driver.ClearRequest(transaction, storeName, object.toJSON(), options)
      else
        @logger "Unknown method", method, "is called for", object
    request.execute() if request

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

