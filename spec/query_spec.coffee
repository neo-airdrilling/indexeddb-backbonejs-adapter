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
      query.lowerBound('low', true)
      expect(query._lower).toEqual 'low'
      expect(query._lowerOpen).toEqual true

    it 'defaults to a closed bound', ->
      query.lowerBound('low', true)

      query.lowerBound('lower')
      expect(query._lowerOpen).toEqual false

  describe 'upperBound', ->
    it 'defines the upper bound', ->
      query.upperBound('up', true)
      expect(query._upper).toEqual 'up'
      expect(query._upperOpen).toEqual true

    it 'defaults to a closed bound', ->
      query.upperBound('up', true)

      query.upperBound('upper')
      expect(query._upperOpen).toEqual false

  describe 'bounds', ->
    it 'defines inclusive lower and upper bounds', ->
      query.bounds('low', 'high', true, true)
      expect(query._lower).toEqual 'low'
      expect(query._lowerOpen).toEqual true
      expect(query._upper).toEqual 'high'
      expect(query._upperOpen).toEqual true

    it 'defaults to closed bounds', ->
      query.bounds('low', 'high', true, true)

      query.bounds('low', 'high')
      expect(query._lowerOpen).toEqual false
      expect(query._upperOpen).toEqual false

  describe 'only', ->
    it 'defines only value', ->
      expect(query.only('bar')._only).toEqual 'bar'

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

