# Method used by Backbone for sync of data with data store. It was initially designed to work with "server side" APIs, This wrapper makes
# it work with the local indexedDB stuff. It uses the schema attribute provided by the object.
# The wrapper keeps an active Executuon Queue for each "schema", and executes querues agains it, based on the object type (collection or
# single model), but also the method... etc.
# Keeps track of the connections
IndexedDBBackbone.Databases = {}
IndexedDBBackbone._schemas = {}

IndexedDBBackbone.describe = (dbName) ->
  IndexedDBBackbone._schemas[dbName] = IndexedDBBackbone.IDBSchema.describe(dbName)

IndexedDBBackbone._getDriver = (databaseName) ->
  Databases = IndexedDBBackbone.Databases
  schema = IndexedDBBackbone._schemas[databaseName]
  if (Databases[schema.id])
    if (Databases[schema.id].version < schema.version()) #TODO: spec it up
      Databases[schema.id].close()
      delete Databases[schema.id]

  Databases[schema.id] ||= new IndexedDBBackbone.Driver(schema)

IndexedDBBackbone.sync = (method, object, options) ->
  switch method
    when "closeall"
      _.each IndexedDBBackbone.Databases, (database) ->
        database.close()
      # Clean up active databases object.
      IndexedDBBackbone.Databases = {}

    when "begin"
      if object instanceof Array
        objects = object
      else
        objects = [object]

      dbName = objects[0].database
      storeNames = _.chain(objects).map((obj) -> obj.storeName).uniq().value()

      IndexedDBBackbone._getDriver(dbName).begin storeNames, options

    when "commit", "abort"
      if object instanceof Array
        objects = object
      else
        objects = [object]

      dbName = objects[0].database
      IndexedDBBackbone._getDriver(dbName)[method]()

    when "read"
      if object instanceof Backbone.Model
        IndexedDBBackbone._getDriver(object.database).get object.storeName, object.toJSON(), options
      else
        options = _.extend({}, { query: object._idbQuery || new IndexedDBBackbone.IDBQuery(object.storeName) }, options)
        IndexedDBBackbone._getDriver(object.database).query object.storeName, options

    when "create", "update"
      if method == "create"
        method = "add"
        # this will be ignored if store doesn't have a keyPath and uses key generator
        object.set(object.idAttribute, IndexedDBBackbone.guid()) unless object.id?
      else
        method = "put"

      options = _.extend {}, options, { key: object.id }
      IndexedDBBackbone._getDriver(object.database)[method] object.storeName, object.toJSON(), options

    when "delete"
      if id = object.id || object.cid
        IndexedDBBackbone._getDriver(object.database).delete object.storeName, id, options
      else
        IndexedDBBackbone._getDriver(object.database).clear object.storeName, options

    else
      @logger "Unhandled sync method:", method

if (typeof exports == 'undefined')
  Backbone.ajaxSync = Backbone.sync
  Backbone.sync = IndexedDBBackbone.sync
else
  exports.sync = IndexedDBBackbone.sync

# window.addEventListener "unload", () ->
#   Backbone.sync("closeall")

