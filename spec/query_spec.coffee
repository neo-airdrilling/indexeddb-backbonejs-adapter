describe 'IDBQuery', ->
  IDBQuery = IndexedDBBackbone.IDBQuery

  describe 'constructor', ->
    it "defines the store name", ->
      expect(new IDBQuery('foo')._storeName).toEqual 'foo'

    it "defines the index name", ->
      expect(new IDBQuery('foo', 'bar')._indexName).toEqual 'bar'

    it "defaults to no index", ->
      expect(new IDBQuery('foo')._indexName).toBeNull()

  describe 'limit', ->
    it 'defines the limit', ->
      expect(new IDBQuery('foo').limit(4)._limit).toEqual 4

  describe 'offset', ->
    it 'defines the offset', ->
      expect(new IDBQuery('foo').offset(4)._offset).toEqual 4

  describe 'lowerBound', ->
    it 'defines the lower bound', ->
      query = new IDBQuery('foo').lowerBound('low', true)
      expect(query._lower).toEqual 'low'
      expect(query._lowerOpen).toEqual true

    it 'defaults to a closed bound', ->
      query = new IDBQuery('foo').lowerBound('low', true)

      query.lowerBound('lower')
      expect(query._lowerOpen).toEqual false

  describe 'upperBound', ->
    it 'defines the upper bound', ->
      query = new IDBQuery('foo').upperBound('up', true)
      expect(query._upper).toEqual 'up'
      expect(query._upperOpen).toEqual true

    it 'defaults to a closed bound', ->
      query = new IDBQuery('foo').upperBound('up', true)

      query.upperBound('upper')
      expect(query._upperOpen).toEqual false

  describe 'bounds', ->
    it 'defines inclusive lower and upper bounds', ->
      query = new IDBQuery('foo').bounds('low', 'high', true, true)
      expect(query._lower).toEqual 'low'
      expect(query._lowerOpen).toEqual true
      expect(query._upper).toEqual 'high'
      expect(query._upperOpen).toEqual true

    it 'defaults to closed bounds', ->
      query = new IDBQuery('foo').bounds('low', 'high', true, true)

      query.bounds('low', 'high')
      expect(query._lowerOpen).toEqual false
      expect(query._upperOpen).toEqual false

  describe 'only', ->
    it 'defines only value', ->
      expect(new IDBQuery('foo').only('bar')._only).toEqual 'bar'

  describe 'direction', ->
    it 'defines direction value', ->
      expect(new IDBQuery('foo').desc()._direction).toEqual IndexedDBBackbone.IDBCursor.PREV
      expect(new IDBQuery('foo').asc()._direction).toEqual IndexedDBBackbone.IDBCursor.NEXT

    it 'defaults to asc', ->
      expect(new IDBQuery('foo')._direction).toEqual IndexedDBBackbone.IDBCursor.NEXT

