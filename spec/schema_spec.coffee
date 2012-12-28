DB_NAME = 'movies-db'
db = undefined
indexedDB = window.webkitIndexedDB

describe 'IDBSchema', ->
  schema = undefined

  beforeEach ->
    schema = IDBSchema.describe(DB_NAME)

  describe '.describe', ->
    it "should initialize a new schema object", ->
      expect(schema.id).toEqual(DB_NAME)

  describe 'migrate', ->
    it 'creates migrations', ->
      schema.migrate ->
        @
      expect(schema.migrations.length).toEqual(1)

    it 'is chainable', ->
      schema.migrate( ->
        @
      ).migrate( ->
        @
      )
      expect(schema.migrations.length).toEqual(2)

  applySchemaAndExpect = (schema, expectBlock) ->
    asyncTest ->
      idb = IndexedDBBackbone.indexedDB
      deleteRequest = idb.deleteDatabase(schema.id)
      deleteRequest.onsuccess = (e) ->
        openRequest = idb.open(schema.id, 1)
        openRequest.onupgradeneeded = (e) ->
          transaction = e.target.transaction
          migration(transaction) for migration in schema.migrations

        openRequest.onsuccess = (e) ->
          db = e.target.result
          expectBlock db
          db.close()
          testDone()

  describe 'createStore', ->
    beforeEach ->
      schema.createStore('movies')

    it 'should create a migration', ->
      expect(schema.migrations.length).toEqual(1)

    it 'should create a store when the migration is run', ->
      applySchemaAndExpect schema, (db) ->
        expect(db.objectStoreNames.length).toEqual 1
        expect(db.objectStoreNames[0]).toEqual('movies')

    it 'applies options', ->
      schema.createStore('music', keyPath: 'id', autoIncrement: true).createStore('books', keyPath: 'ISDN')
      applySchemaAndExpect schema, (db) ->
        expect(db.objectStoreNames.length).toEqual 3

        transaction = db.transaction(db.objectStoreNames)

        movies = transaction.objectStore('movies')
        expect(movies.keyPath).toBeNull()
        expect(movies.autoIncrement).toBeFalsy()

        music = transaction.objectStore('music')
        expect(music.keyPath).toEqual('id')
        expect(music.autoIncrement).toBeTruthy()

        books = transaction.objectStore('books')
        expect(books.keyPath).toEqual('ISDN')
        expect(books.autoIncrement).toBeFalsy()

  describe 'deleteStore', ->
    it 'should delete the store when the migration is run', ->
      schema.createStore('movies').createStore('music').deleteStore('movies')

      applySchemaAndExpect schema, (db) ->
        expect(db.objectStoreNames.length).toEqual 1
        expect(db.objectStoreNames[0]).toEqual('music')

    it 'can create a store right after deleting one with the same name', ->
      schema.createStore('movies').deleteStore('movies').createStore('movies')
      applySchemaAndExpect schema, (db) ->
        expect(db.objectStoreNames.length).toEqual 1
        expect(db.objectStoreNames[0]).toEqual('movies')

  describe 'createIndex', ->
    it 'should create index for the store when the migration is run', ->
      schema.createStore('movies').createIndex('movies', 'actorsIndex', 'actors.name')

      applySchemaAndExpect schema, (db) ->
        expect(db.objectStoreNames.length).toEqual 1
        expect(db.objectStoreNames[0]).toEqual('movies')

        transaction = db.transaction(['movies'], 'readonly')
        store = transaction.objectStore('movies')
        index = store.index('actorsIndex')
        expect(index.keyPath).toEqual('actors.name')

    it 'applies options', ->
      schema.createStore('movies')
        .createIndex('movies', 'name', 'name')
        .createIndex('movies', 'actors', 'actorIds', multiEntry: true)
        .createIndex('movies', 'imdbURL', 'url', unique: true)

      applySchemaAndExpect schema, (db) ->
        transaction = db.transaction(['movies'], 'readonly')
        store = transaction.objectStore('movies')

        index = store.index('name')
        expect(index.multiEntry).toBeFalsy()
        expect(index.unique).toBeFalsy()

        index = store.index('actors')
        expect(index.multiEntry).toBeTruthy()
        expect(index.unique).toBeFalsy()

        index = store.index('imdbURL')
        expect(index.multiEntry).toBeFalsy()
        expect(index.unique).toBeTruthy()

  describe 'deleteIndex', ->
    it 'should delete the index for the store when the migration is run', ->
      schema.createStore('movies')
        .createIndex('movies', 'actorsIndex', 'actors.name')
        .createIndex('movies', 'otherIndex', 'fooBar')
        .deleteIndex('movies', 'actorsIndex')

      applySchemaAndExpect schema, (db) ->
        transaction = db.transaction(['movies'], 'readonly')
        store = transaction.objectStore('movies')
        expect(store.indexNames.length).toEqual 1
        expect(store.indexNames[0]).toEqual 'otherIndex'

  describe 'onupgradeneeded', ->
    it 'applies the necessary migrations', ->
      asyncTest ->
        idb = IndexedDBBackbone.indexedDB
        deleteRequest = idb.deleteDatabase(schema.id)
        deleteRequest.onsuccess = (e) ->
          openRequest = idb.open(schema.id, 1)

          openRequest.onupgradeneeded = ->
            # Do nothing, just bumping the version

          openRequest.onsuccess = (e) ->
            db = e.target.result
            db.close()

            # Now database is closed and in version 1

            schema
              .createStore('movies')
              .createStore('music')
              .createStore('books')

            openRequest = idb.open(schema.id, 2)

            openRequest.onupgradeneeded = schema.onupgradeneeded

            openRequest.onsuccess = (e) ->
              db = e.target.result
              expect(db.objectStoreNames.length).toEqual 1
              expect(db.objectStoreNames[0]).toEqual 'music'
              db.close()
              testDone()

