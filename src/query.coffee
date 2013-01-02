class IndexedDBBackbone.IDBQuery
  _storeName: null
  _indexName: null

  _offset: 0
  _limit: null
  _direction: IndexedDBBackbone.IDBCursor.NEXT

  _lower: null
  _upper: null

  _lowerOpen: false
  _upperOpen: false

  constructor: (@_storeName, @_indexName = null) ->

  limit: (@_limit) -> @
  offset: (@_offset) -> @

  lowerBound: (@_lower, @_lowerOpen = false) -> @
  upperBound: (@_upper, @_upperOpen = false) -> @
  bounds: (@_lower, @_upper, @_lowerOpen = false, @_upperOpen = false) -> @
  only: (@_only) -> @

  asc: ->
    @_direction = IndexedDBBackbone.IDBCursor.NEXT
    @

  desc: ->
    @_direction = IndexedDBBackbone.IDBCursor.PREV
    @

