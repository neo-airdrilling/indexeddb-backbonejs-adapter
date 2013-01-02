class IndexedDBBackbone.IDBSchema
  _logChannel: false

  @describe: (id) ->
    return new @(id)

  constructor: (@id) ->
    @migrations = []

  migrate: (migration) ->
    @migrations.push(migration)
    @

  createStore: (name, options) ->
    @migrate (transaction) ->
      transaction.db.createObjectStore(name, options)

  deleteStore: (name) ->
    @migrate (transaction) ->
      transaction.db.deleteObjectStore(name)

  createIndex: (store, name, keyPath, options) ->
    @migrate (transaction) ->
      store = transaction.objectStore(store)
      store.createIndex(name, keyPath, options)

  deleteIndex: (store, name) ->
    @migrate (transaction) ->
      store = transaction.objectStore(store)
      store.deleteIndex(name)

  onupgradeneeded: (e) =>
    transaction = e.target.transaction
    migration(transaction) for migration in @migrations[e.oldVersion...e.newVersion]

  version: ->
    @migrations.length

  logChannel: (value) ->
    unless value == undefined
      @_logChannel = value
    else
      @_logChannel

