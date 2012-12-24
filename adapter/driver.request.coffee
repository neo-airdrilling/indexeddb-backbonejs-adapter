class Driver.Request
  constructor: (transaction, storeName, objectJSON, options) ->
    @objectJSON = objectJSON
    @options = options

    @store = transaction.objectStore(storeName)

Driver.Request.prototype = _.extend(Driver.Request.prototype, {
  execute: ->
    request = @run()
    @bindCallbacks(request)

  bindCallbacks: (request) ->
    request.onerror = (e) =>
      @options.error(e)
    request.onsuccess = (e) =>
      @options.success(json)
})

Driver.AddRequest = {}

Driver.AddRequest.prototype = _.extend(Driver.Request.prototype, {
  run: ->
    if (@objectJSON.id == undefined) then @objectJSON.id = guid()
    if (@objectJSON.id == null) then delete @objectJSON.id

    if @store.keyPath then @store.add(@objectJSON) else @store.add(@objectJSON, @objectJSON.id)
})
