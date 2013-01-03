describe 'IDBQuery', ->
  IDBQuery = IndexedDBBackbone.IDBQuery

  query = null

  beforeEach ->
    query = new IDBQuery('foo')

  describe 'constructor', ->
    it "defines the store name", ->
      expect(new IDBQuery('foo')._storeName).toEqual 'foo'

    it "defines the index name", ->
      expect(new IDBQuery('foo', 'bar')._indexName).toEqual 'bar'

    it "defaults to no index", ->
      expect(new IDBQuery('foo')._indexName).toBeNull()

  describe 'limit', ->
    it 'defines the limit', ->
      expect(query.limit(4)._limit).toEqual 4

  describe 'offset', ->
    it 'defines the offset', ->
      expect(query.offset(4)._offset).toEqual 4

  describe 'lowerBound', ->
    it 'defines the lower bound', ->
      range = query.lowerBound('low', true).getKeyRange()
      expect(range.lower).toEqual 'low'
      expect(range.lowerOpen).toEqual true
      expect(range.upper).not.toBeDefined()

    it 'defaults to a closed bound', ->
      range = query.lowerBound('low', true).lowerBound('low').getKeyRange()
      expect(range.lowerOpen).toEqual false

  describe 'upperBound', ->
    it 'defines the upper bound', ->
      range = query.upperBound('up', true).getKeyRange()
      expect(range.upper).toEqual 'up'
      expect(range.upperOpen).toEqual true
      expect(range.lower).not.toBeDefined()

    it 'defaults to a closed bound', ->
      range = query.upperBound('high', true).upperBound('high').getKeyRange()
      expect(range.upperOpen).toEqual false

  describe 'bounds', ->
    it 'defines inclusive lower and upper bounds', ->
      range = query.bounds('lower', 'upper', true, true).getKeyRange()
      expect(range.lower).toEqual 'lower'
      expect(range.lowerOpen).toEqual true
      expect(range.upper).toEqual 'upper'
      expect(range.upperOpen).toEqual true

    it 'defaults to closed bounds', ->
      range = query.bounds('lower', 'upper', true, true).bounds('lower', 'upper').getKeyRange()
      expect(range.lowerOpen).toEqual false
      expect(range.upperOpen).toEqual false

  describe 'only', ->
    it 'defines a closed bound over the given value', ->
      range = query.only('bar').getKeyRange()
      expect(range.lower).toEqual 'bar'
      expect(range.lowerOpen).toEqual false
      expect(range.upper).toEqual 'bar'
      expect(range.upperOpen).toEqual false

  describe 'direction', ->
    describe 'asc', ->
      it 'sets asc to true', ->
        query._asc = false
        expect(query.asc()._asc).toEqual(true)

    describe 'desc', ->
      it 'sets asc to false', ->
        query._asc = true
        expect(query.desc()._asc).toEqual(false)

    describe 'unique', ->
      it 'sets unique', ->
        expect(query.unique(true)._unique).toEqual true
        expect(query.unique(false)._unique).toEqual false

      it 'defaults to true', ->
        expect(query.unique()._unique).toEqual true

    describe 'getDirection', ->
      it 'defaults to NEXT', ->
        expect(query.getDirection()).toEqual IndexedDBBackbone.IDBCursor.NEXT

      it 'gets the IDB direction based on asc and unique', ->
        expect(query.desc().unique(false).getDirection()).toEqual IndexedDBBackbone.IDBCursor.PREV
        expect(query.desc().unique(true).getDirection()).toEqual IndexedDBBackbone.IDBCursor.PREV_NO_DUPLICATE
        expect(query.asc().unique(false).getDirection()).toEqual IndexedDBBackbone.IDBCursor.NEXT
        expect(query.asc().unique(true).getDirection()).toEqual IndexedDBBackbone.IDBCursor.NEXT_NO_DUPLICATE

  describe 'getKeyRange', ->
    it 'returns an IDBKeyRange instance when a bound exists', ->
      query.lowerBound('foo')
      expect(query.getKeyRange() instanceof IndexedDBBackbone.IDBKeyRange).toBeTruthy()

    it 'returns null if no range is given', ->
      expect(query.getKeyRange()).toBeNull()

