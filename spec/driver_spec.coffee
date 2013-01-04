describe 'IndexedDBBackbone.Driver', ->
  deleteDB('driverTest')
  schema = IndexedDBBackbone.describe('driverTest')
    .createStore('store_with_inline_key', keyPath: 'ssn')
    .createIndex('store_with_inline_key', 'nameIndex', 'name')
    .createStore('store_with_key_generator', autoIncrement: true)
    .createStore('store_with_no_key_generator')

  indexedDB = IndexedDBBackbone.indexedDB
  driver = null
  john = { name: 'John', ssn: 1337 }

  withStore = (storeName, callback) ->
    asyncTest ->
      driver.add storeName, john,
        success: (e) ->
          callback()

  expectStore = (storeName, expectationBlock) ->
    transaction = driver.db.transaction(storeName)
    store = transaction.objectStore(storeName)
    expectationBlock(store)
    transaction.oncomplete = testDone
    transaction.onerror = (e) ->
      fail("Transaction fails", e)

  cleanDatabase = ->
    asyncTest ->
      transaction = driver.db.transaction(['store_with_inline_key', 'store_with_key_generator', 'store_with_no_key_generator'], IndexedDBBackbone.IDBTransaction.READ_WRITE)
      transaction.objectStore('store_with_inline_key').clear()
      transaction.objectStore('store_with_key_generator').clear()
      transaction.objectStore('store_with_no_key_generator').clear()
      transaction.oncomplete = testDone
      driver.close()

  beforeEach ->
    runs ->
      driver = new IndexedDBBackbone.Driver(schema)

    waitsFor ->
      driver.state == 'open'
    , "db to open", 500

  afterEach ->
    cleanDatabase()

  describe 'begin', ->
    it "initializes Driver's local readwrite transaction", ->
      runs ->
        expect(driver._transaction?).toBeFalsy()
        driver.begin ['store_with_inline_key']
        expect(driver._transaction?).toBeTruthy()
        expect(driver._transaction.mode).toEqual('readwrite')

    it "uses a single transaction for all operations", ->
      runs ->
        spyOn(driver.db, 'transaction').andCallThrough()

        driver.begin ['store_with_inline_key']
        driver.add('store_with_inline_key', { ssn: 1 })
        driver.put('store_with_inline_key', { ssn: 1 }, key: 1)
        driver.delete('store_with_inline_key', 1)
        driver.get('store_with_inline_key', { ssn: 1 })
        expect(driver.db.transaction.callCount).toEqual(1)

  describe 'commit', ->
    it "removes the local transaction", ->
      runs ->
        driver.begin ['store_with_inline_key']
        driver.commit()
        expect(driver._transaction?).toBeFalsy()

  describe 'abort', ->
    it "aborts and removes the local transaction", ->
      runs ->
        driver.begin ['store_with_inline_key']
        spy = spyOn(driver._transaction, 'abort').andCallThrough()
        driver.abort()
        expect(spy).toHaveBeenCalled()
        expect(driver._transaction?).toBeFalsy()

  describe 'get', ->
    describe 'with an object with keyPath', ->
      it 'retrieves the object', ->
        withStore 'store_with_inline_key', ->
          driver.get 'store_with_inline_key', { ssn: 1337 },
            success: (object) ->
              expect(object.name).toEqual('John')
              testDone()

    describe 'with an indexName', ->
      it 'retrieves the object', ->
        withStore 'store_with_inline_key', ->
          driver.get 'store_with_inline_key', { name: 'John' },
            indexName: 'nameIndex'
            success: (object) ->
              expect(object).toEqual(john)
              testDone()

    describe 'otherwise', ->
      it 'goes to error', ->
        asyncTest ->
          driver.get 'store_with_inline_key', { name: 'John' },
            error: testDone()

  describe 'add', ->
    describe 'inline-key', ->
      it 'adds a new object to the store with valid object', ->
        withStore 'store_with_inline_key', ->
          expectStore 'store_with_inline_key', (store) ->
            store.get(1337).onsuccess = (e) ->
              expect(e.target.result).toEqual(john)

      it 'raises an error on duplicated key', ->
        withStore 'store_with_inline_key', ->
          driver.add 'store_with_inline_key', john,
            error: testDone

    describe 'with key generator', ->
      it 'uses browser\'s generated key', ->
        asyncTest ->
          driver.add 'store_with_key_generator', { name: 'Smith' },
            success: (e) ->
              expectStore 'store_with_key_generator', (store) ->
                store.count().onsuccess = (e) ->
                  expect(e.target.result).toEqual 1
                store.openCursor().onsuccess = (e) ->
                  savedObject = e.target.result
                  expect(savedObject.value.name).toEqual 'Smith'
                  expect(savedObject.key).toBeDefined()

      it 'ignores provided key', ->
        asyncTest ->
          driver.add 'store_with_key_generator', { name: 'Smith' },
            key: 1337
            success: (e) ->
              expectStore 'store_with_key_generator', (store) ->
                store.count().onsuccess = (e) ->
                  expect(e.target.result).toEqual 1
                store.openCursor().onsuccess = (e) ->
                  savedObject = e.target.result
                  expect(savedObject.value.name).toEqual 'Smith'
                  expect(savedObject.key).not.toEqual(1337)

    describe 'without key generator', ->
      it 'saves with provided key', ->
        asyncTest ->
          driver.add 'store_with_no_key_generator', { name: 'Smith' },
            key: 1337
            success: (e) ->
              expectStore 'store_with_no_key_generator', (store) ->
                store.count().onsuccess = (e) ->
                  expect(e.target.result).toEqual 1
                store.get(1337).onsuccess = (e) ->
                  expect(e.target.result.name).toEqual 'Smith'

      it 'raises an error with duplicated key', ->
        asyncTest ->
          driver.add 'store_with_no_key_generator', john,
            key: 1337
            success: (e) ->
              driver.add 'store_with_no_key_generator', { name: 'Smith' },
                key: 1337
                error: testDone

  describe 'put', ->
    describe 'with inline-key', ->
      it 'updates an existing object in the store if it exists', ->
        withStore 'store_with_inline_key', ->
          driver.put 'store_with_inline_key', { name: 'Smith', ssn: 1337 }
            success: (e) ->
              expectStore 'store_with_inline_key', (store) ->
                store.count().onsuccess = (e) ->
                  expect(e.target.result).toEqual 1
                store.get(1337).onsuccess = (e) ->
                  expect(e.target.result).toEqual({ name: 'Smith', ssn: 1337 })

    describe 'with key generator', ->
      it 'updates the record with valid key', ->
        withStore 'store_with_key_generator', ->
          transaction = driver.db.transaction('store_with_key_generator')
          transaction.objectStore('store_with_key_generator').openCursor().onsuccess = (e) ->
            key = e.target.result.key

            driver.put 'store_with_key_generator', { name: 'Smith' },
              key: key
              success: (e) ->
                expectStore 'store_with_key_generator', (store) ->
                  store.count().onsuccess = (e) ->
                    expect(e.target.result).toEqual 1
                  store.get(key).onsuccess = (e) ->
                    expect(e.target.result.name).toEqual 'Smith'

      it 'adds a new record without the key', ->
        withStore 'store_with_key_generator', ->
          driver.put 'store_with_key_generator', { name: 'Smith' },
            success: (e) ->
              expectStore 'store_with_key_generator', (store) ->
                store.count().onsuccess = (e) ->
                  expect(e.target.result).toEqual 2

    describe 'without key generator', ->
      it 'updates the record with valid key', ->
        asyncTest ->
          driver.add 'store_with_no_key_generator', john,
            key: 1337
            success: (e) ->
              transaction = driver.db.transaction('store_with_no_key_generator')
              transaction.objectStore('store_with_no_key_generator').openCursor().onsuccess = (e) ->
                key = e.target.result.key

                driver.put 'store_with_no_key_generator', { name: 'Smith' },
                  key: key
                  success: (e) ->
                    expectStore 'store_with_no_key_generator', (store) ->
                      store.count().onsuccess = (e) ->
                        expect(e.target.result).toEqual 1
                      store.get(key).onsuccess = (e) ->
                        expect(e.target.result.name).toEqual 'Smith'

  describe 'delete', ->
    it 'deletes the indicated object', ->
      withStore 'store_with_inline_key', ->
        driver.add 'store_with_inline_key', { name: 'Smith', ssn: 1338 }
          success: ->
            driver.delete 'store_with_inline_key', 1338
              success: (e) ->
                expectStore 'store_with_inline_key', (store) ->
                  store.count().onsuccess = (e) ->
                    expect(e.target.result).toEqual 1
                  store.openCursor().onsuccess = (e) ->
                    expect(e.target.result.value).toEqual john

  describe 'clear', ->
    it 'clears the entire store', ->
      withStore 'store_with_inline_key', ->
        driver.clear 'store_with_inline_key'
          success: ->
            expectStore 'store_with_inline_key', (store) ->
              store.count().onsuccess = (e) ->
                expect(e.target.result).toEqual 0

