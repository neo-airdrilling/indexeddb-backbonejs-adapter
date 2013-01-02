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
  only: (@_only) -> @

  asc: ->
    @_asc = true
    @

  desc: ->
    @_asc = false
    @

  unique: (@_unique = true) ->
    @

  getDirection: () ->
    if @_asc
      if @_unique then Dir.NEXT_NO_DUPLICATE else Dir.NEXT
    else
      if @_unique then Dir.PREV_NO_DUPLICATE else Dir.PREV

