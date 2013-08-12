class IndexedDBBackbone.Driver
  @db: null
  @stack: null
  @state: 'closed'

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
      @db.onversionchange = (e) =>
        @logger("Database version changes on another tab. Closing this tab's connection.")
        @db.close()
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

  begin: (storeNames, options={}) ->
    @execute =>
      @_transaction = @db.transaction(storeNames, IndexedDBBackbone.IDBTransaction.READ_WRITE)
      @_transaction.oncomplete = options.success if options?.success?
      @_transaction.onabort = options.abort if options?.abort?
      @_transaction.onerror = options.error if options?.error?

      try
        options.callback(@_transaction)
      catch error
        options?.error?(error)

  get: (storeName, object, options={}) ->
    @execute =>
      request = new IndexedDBBackbone.Driver.GetOperation(@db, storeName, object, options)
      request.execute()

  query: (storeName, options={}) ->
    @execute =>
      request = new IndexedDBBackbone.Driver.Query(@db, storeName, options)
      request.execute()

  add: (storeName, object, options={}) ->
    @execute =>
      request = new IndexedDBBackbone.Driver.AddOperation(@db, [storeName], object, options)
      request.execute()

  put: (storeName, object, options={}) ->
    @execute =>
      request = new IndexedDBBackbone.Driver.PutOperation(@db, [storeName], object, options)
      request.execute()

  delete: (storeName, key, options={}) ->
    @execute =>
      request = new IndexedDBBackbone.Driver.DeleteOperation(@db, storeName, key, options)
      request.execute()

  clear: (storeName, options={}) ->
    @execute =>
      request = new IndexedDBBackbone.Driver.ClearOperation(@db, storeName, options)
      request.execute()

