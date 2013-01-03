class IndexedDBBackbone.Driver extends IndexedDBBackbone.Driver

  begin: (storeNames, options) ->
    @execute =>
      @_transaction = @db.transaction(storeNames, IndexedDBBackbone.IDBTransaction.READ_WRITE)
      @_transaction.oncomplete = options.success if options?.success?
      @_transaction.onabort = options.abort if options?.abort?

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
      transaction = @transaction(storeNames)
      if object.id || object.cid
        request = new IndexedDBBackbone.Driver.GetRequest(transaction, storeNames, object.toJSON(), options)
      else
        options = _.extend({}, { query: object._idbQuery || new IndexedDBBackbone.IDBQuery(object.storeName) }, options)
        request = new IndexedDBBackbone.Driver.Query(transaction, storeNames, null, options)
      request.execute()

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

