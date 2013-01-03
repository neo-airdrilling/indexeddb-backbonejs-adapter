Dir = IndexedDBBackbone.IDBCursor

class IndexedDBBackbone.IDBQuery
  _storeName: null
  _indexName: null

  _offset: 0
  _limit: null

  _asc: true
  _unique: false

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
  only: (value) ->
    @_lower = value
    @_upper = value
    @_lowerOpen = false
    @_upperOpen = false
    @

  asc: ->
    @_asc = true
    @

  desc: ->
    @_asc = false
    @

  unique: (@_unique = true) ->
    @

  getKeyRange: ->
    if @_lower? && @_upper?
      IndexedDBBackbone.IDBKeyRange.bound(@_lower, @_upper, @_lowerOpen, @_upperOpen)
    else if @_lower?
      IndexedDBBackbone.IDBKeyRange.lowerBound(@_lower, @_lowerOpen)
    else if @_upper?
      IndexedDBBackbone.IDBKeyRange.upperBound(@_upper, @_upperOpen)
    else
      null

  getDirection: ->
    if @_asc
      if @_unique then Dir.NEXT_NO_DUPLICATE else Dir.NEXT
    else
      if @_unique then Dir.PREV_NO_DUPLICATE else Dir.PREV

