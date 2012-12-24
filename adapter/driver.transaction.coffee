class window.Driver extends window.Driver
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
    debugLog("execute : " + method +  " on " + storeName + " for " + object.id) unless @nolog
    switch method
      when "create" then @create(storeName, object, options)
      when "read"
        if (object.id || object.cid)
          @read(storeName, object, options) # It's a model
        else
          @query(storeName, object, options) # It's a collection
      when "update" then @update(storeName, object, options) # We may want to check that this is not a collection. TOFIX
      when "delete"
        if (object.id || object.cid)
            @delete(storeName, object, options)
        else
            @clear(storeName, object, options)
      else
        debugLog("HUH")

  # Writes the json to the storeName in db. It is a create operations, which means it will fail if the key already exists
  # options are just success and error callbacks.
  create: (storeName, object, options) ->
    writeTransaction = @db.transaction([storeName], 'readwrite')
    # @_track_transaction(writeTransaction);
    store = writeTransaction.objectStore(storeName)
    json = object.toJSON()

    if (json.id == undefined) then json.id = guid()
    if (json.id == null) then delete json.id

    if (!store.keyPath)
      writeRequest = store.add(json, json.id)
    else
      writeRequest = store.add(json)

    writeRequest.onerror = (e) ->
      options.error(e)
    writeRequest.onsuccess = (e) ->
      options.success(json)

  # Writes the json to the storeName in db. It is an update operation, which means it will overwrite the value if the key already exist
  # options are just success and error callbacks.
  update: (storeName, object, options) ->
      writeTransaction = @db.transaction([storeName], 'readwrite')
      #@_track_transaction(writeTransaction)
      store = writeTransaction.objectStore(storeName)
      json = object.toJSON()
      writeRequest

      if (!json.id) then json.id = guid()

      if (!store.keyPath)
        writeRequest = store.put(json, json.id)
      else
        writeRequest = store.put(json)

      writeRequest.onerror = (e) ->
        options.error(e)
      writeRequest.onsuccess = (e) ->
        options.success(json)

  # Reads from storeName in db with json.id if it's there of with any json.xxxx as long as xxx is an index in storeName
  read: (storeName, object, options) ->
    readTransaction = @db.transaction([storeName], "readonly")
    @_track_transaction(readTransaction)

    store = readTransaction.objectStore(storeName)
    json = object.toJSON()


    getRequest = null
    if (json.id)
      getRequest = store.get(json.id)
    else
      # We need to find which index we have
      _.each store.indexNames, (key, index) ->
        index = store.index(key)
        if (json[index.keyPath] && !getRequest)
          getRequest = index.get(json[index.keyPath])
    if (getRequest)
      getRequest.onsuccess = (event) ->
          if (event.target.result)
            options.success(event.target.result)
          else
            options.error("Not Found")
      getRequest.onerror = () ->
        options.error("Not Found") # We couldn't find the record.
    else
        ptions.error("Not Found") # We couldn't even look for it, as we don't have enough data.

  # Deletes the json.id key and value in storeName from db.
  delete: (storeName, object, options) ->
      deleteTransaction = @db.transaction([storeName], 'readwrite')
      #@_track_transaction(deleteTransaction)

      store = deleteTransaction.objectStore(storeName)
      json = object.toJSON()

      deleteRequest = store.delete(json.id)
      deleteRequest.onsuccess = (event) ->
          options.success(null)
      deleteRequest.onerror = (event) ->
          options.error("Not Deleted")

  # Clears all records for storeName from db.
  clear: (storeName, object, options) ->
    deleteTransaction = @db.transaction([storeName], "readwrite")
    #@_track_transaction(deleteTransaction)

    store = deleteTransaction.objectStore(storeName)

    deleteRequest = store.clear()
    deleteRequest.onsuccess = (event) ->
      options.success(null)
    deleteRequest.onerror = (event) ->
      options.error("Not Cleared")


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
            bounds = IDBKeyRange.bound(lower, upper, true, true)

            if (options.conditions[index.keyPath][0] > options.conditions[index.keyPath][1])
              # Looks like we want the DESC order
              readCursor = index.openCursor(bounds, window.IDBCursor.PREV || "prev")
            else
              # We want ASC order
              readCursor = index.openCursor(bounds, window.IDBCursor.NEXT || "next")
          else if (options.conditions[index.keyPath] != undefined)
            bounds = IDBKeyRange.only(options.conditions[index.keyPath])
            readCursor = index.openCursor(bounds)
    else
      # No conditions, use the index
      if (options.range)
        lower = if options.range[0] > options.range[1] then options.range[1] else options.range[0]
        upper = if options.range[0] > options.range[1] then options.range[0] else options.range[1]
        bounds = IDBKeyRange.bound(lower, upper)
        if (options.range[0] > options.range[1])
          readCursor = store.openCursor(bounds, window.IDBCursor.PREV || "prev")
        else
          readCursor = store.openCursor(bounds, window.IDBCursor.NEXT || "next")
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

