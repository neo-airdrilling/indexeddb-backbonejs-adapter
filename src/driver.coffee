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

