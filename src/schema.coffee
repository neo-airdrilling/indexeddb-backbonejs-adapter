class IDBSchema

  @describe: (id) ->
    return new IDBSchema(id)

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

window.IDBSchema = IDBSchema

