class IndexedDBBackbone.Driver
  @db: null
  @stack: null
  @state: 'closed'
  @_transaction: null

  constructor: (@schema) ->
    @stack = []
    @logger = IndexedDBBackbone.getLogger(@schema.logChannel())

    @open()

  open: ->
    name = @schema.id
    version = @schema.version()

    @logger "opening database", name, "in version #", version
    @state = 'opening'

    dbRequest = IndexedDBBackbone.indexedDB.open(name, version)
    dbRequest.onupgradeneeded = (e) =>
      @logger("onupgradeneeded = #{e.oldVersion} => #{e.newVersion}")
      @schema.onupgradeneeded(e)

    dbRequest.onsuccess = (e) =>
      @db = e.target.result
      @state = 'open'
      @ready()

    dbRequest.onblocked = (e) => @logger("blocked")
    dbRequest.onerror = (e) => @logger("Couldn't not connect to the database")
    dbRequest.onabort = (e) => @logger("Connection to the database aborted")

  close: () ->
    if @db?
      @state = 'closed'
      @db.close()
      @db = null

  ready: () ->
    operation() while operation = @stack.shift()

  execute: (operation) ->
    switch @state
      when 'closed'
        @open()
        @stack.push operation
      when 'opening'
        @stack.push operation
      when 'open'
        operation()

  # Operations

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

  get: (storeName, object, options) ->
    @execute =>
      transaction = @transaction(storeName)
      request = new IndexedDBBackbone.Driver.GetOperation(transaction, storeName, object, options)
      request.execute()

  query: (storeName, options) ->
    @execute =>
      transaction = @transaction(storeName)
      request = new IndexedDBBackbone.Driver.Query(transaction, storeName, options)
      request.execute()

  add: (storeName, object, options) ->
    @execute =>
      transaction = @transaction([storeName], IndexedDBBackbone.IDBTransaction.READ_WRITE)
      request = new IndexedDBBackbone.Driver.AddOperation(transaction, [storeName], object, options)
      request.execute()

  put: (storeName, object, options) ->
    @execute =>
      transaction = @transaction([storeName], IndexedDBBackbone.IDBTransaction.READ_WRITE)
      request = new IndexedDBBackbone.Driver.PutOperation(transaction, [storeName], object, options)
      request.execute()

  delete: (storeName, key, options) ->
    @execute =>
      transaction = @transaction([storeName], IndexedDBBackbone.IDBTransaction.READ_WRITE)
      request = new IndexedDBBackbone.Driver.DeleteOperation(transaction, storeName, key, options)
      request.execute()

  clear: (storeName, options) ->
    @execute =>
      transaction = @transaction([storeName], IndexedDBBackbone.IDBTransaction.READ_WRITE)
      request = new IndexedDBBackbone.Driver.ClearOperation(transaction, storeName, options)
      request.execute()

  transaction: (storeNames, mode = IndexedDBBackbone.IDBTransaction.READ_ONLY) ->
    @_transaction || @db.transaction(storeNames, mode)

