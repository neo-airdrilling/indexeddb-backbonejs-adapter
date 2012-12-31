class IndexedDBBackbone.Driver
  constructor: (@schema, @nolog) ->
    @error = null
    @transactions = [] # Used to list all transactions and keep track of active ones.
    @db = null
    @stack = []
    @state = 'closed'

    @logger = ->
      unless @nolog
        if window?.console?.log?
          window.console.log.apply window.console, arguments
        else if console?.log?
          console.log apply console, arguments

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
    while args = @stack.shift()
      @_execute args...

  execute: () ->
    switch @state
      when 'closed'
        @open()
        @stack.push arguments
      when 'opening'
        @stack.push arguments
      when 'open'
        @_execute arguments...

