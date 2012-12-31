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
        # driver.begin('foo')
        driver.execute(['foo'], 'begin')
        expect(driver._transaction?).toBeTruthy()
        expect(driver._transaction.mode).toEqual('readwrite')

    it "uses a single transaction for all operations", ->
      runs ->
        spyOn(driver.db, 'transaction').andCallThrough()

        driver.execute(['foo'], 'begin')
        driver.execute('foo', 'create', { toJSON: -> { id: 1 } })
        driver.execute('foo', 'update', { toJSON: -> { id: 1 } })
        driver.execute('foo', 'delete', { toJSON: -> { id: 1 } })
        driver.execute('foo', 'read', { id: 1, toJSON: -> { id: 1 } })
        expect(driver.db.transaction.callCount).toEqual(1)

  describe 'commit', ->
    it "removes the local transaction", ->
      runs ->
        driver.execute(['foo'], 'begin')
        driver.execute(null, 'commit')
        expect(driver._transaction?).toBeFalsy()

  describe 'abort', ->
    it "aborts and removes the local transaction", ->
      runs ->
        driver.execute(['foo'], 'begin')
        spy = spyOn(driver._transaction, 'abort').andCallThrough()
        driver.execute(null, 'abort')
        expect(spy).toHaveBeenCalled()
        expect(driver._transaction?).toBeFalsy()

