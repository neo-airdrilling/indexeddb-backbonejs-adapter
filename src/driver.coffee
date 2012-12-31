class IndexedDBBackbone.Driver
  constructor: (schema, ready, nolog) ->
    @schema = schema
    @ready = ready
    @error = null
    @transactions = [] # Used to list all transactions and keep track of active ones.
    @db = null
    @nolog = nolog

    @logger = ->
      unless @nolog
        if window?.console?.log?
          window.console.log.apply window.console, arguments
        else if console?.log?
          console.log apply console, arguments

    version = schema.version()

    @logger "opening database", schema.id, "in version #", version
    dbRequest = IndexedDBBackbone.indexedDB.open(schema.id, version)
    dbRequest.onupgradeneeded = (e) =>
      @logger("onupgradeneeded = #{e.oldVersion} => #{e.newVersion}")
      @schema.onupgradeneeded(e)

    dbRequest.onsuccess = (e) =>
     @db = e.target.result
     @ready()

    dbRequest.onblocked = (e) => @logger("blocked")
    dbRequest.onerror = (e) => @logger("Couldn't not connect to the database")
    dbRequest.onabort = (e) => @logger("Connection to the database aborted")

  close: () ->
    if @db?
      @db.close()
      @db = null

