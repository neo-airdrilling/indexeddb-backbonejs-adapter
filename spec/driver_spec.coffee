describe 'IndexedDBBackbone.Driver', ->
  schema = IndexedDBBackbone.describe('driverTest').createStore('foo')
  indexedDB = IndexedDBBackbone.indexedDB
  driver = null

  beforeEach ->
    runs ->
      driver = new IndexedDBBackbone.Driver(schema, false)

    waitsFor ->
      driver.state == 'open'
    , "db to open", 500

  afterEach ->
    driver.close()

  describe 'begin', ->
    it "initializes Driver's local readwrite transaction", ->
      runs ->
        expect(driver._transaction?).toBeFalsy()
        driver.begin ['foo']
        expect(driver._transaction?).toBeTruthy()
        expect(driver._transaction.mode).toEqual('readwrite')

    it "uses a single transaction for all operations", ->
      runs ->
        spyOn(driver.db, 'transaction').andCallThrough()

        driver.begin ['foo']
        driver.create('foo', { toJSON: -> { id: 1 } })
        driver.update('foo', { toJSON: -> { id: 1 } })
        driver.delete('foo', { toJSON: -> { id: 1 } })
        driver.read('foo', { id: 1, toJSON: -> { id: 1 } })
        expect(driver.db.transaction.callCount).toEqual(1)

  describe 'commit', ->
    it "removes the local transaction", ->
      runs ->
        driver.begin ['foo']
        driver.commit()
        expect(driver._transaction?).toBeFalsy()

  describe 'abort', ->
    it "aborts and removes the local transaction", ->
      runs ->
        driver.begin ['foo']
        spy = spyOn(driver._transaction, 'abort').andCallThrough()
        driver.abort()
        expect(spy).toHaveBeenCalled()
        expect(driver._transaction?).toBeFalsy()

