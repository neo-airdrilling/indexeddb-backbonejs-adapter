# Method used by Backbone for sync of data with data store. It was initially designed to work with "server side" APIs, This wrapper makes
# it work with the local indexedDB stuff. It uses the schema attribute provided by the object.
# The wrapper keeps an active Executuon Queue for each "schema", and executes querues agains it, based on the object type (collection or
# single model), but also the method... etc.
# Keeps track of the connections
IndexedDBBackbone.Databases = {}
IndexedDBBackbone._schemas = {}

IndexedDBBackbone.describe = (dbName) ->
  IndexedDBBackbone._schemas[dbName] = IDBSchema.describe(dbName)

IndexedDBBackbone._getDriver = (databaseName) ->
  Databases = IndexedDBBackbone.Databases
  schema = IndexedDBBackbone._schemas[databaseName]
  if (Databases[schema.id])
    if (Databases[schema.id].version < schema.version()) #TODO: spec it up
      Databases[schema.id].close()
      delete Databases[schema.id]

  Databases[schema.id] ||= new IndexedDBBackbone.Driver(schema, schema.nolog)

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
      console.log storeNames

      IndexedDBBackbone._getDriver(dbName).execute storeNames, 'begin'

    when "commit"
      if object instanceof Array
        objects = object
      else
        objects = [object]

      dbName = objects[0].database
      IndexedDBBackbone._getDriver(dbName).execute null, 'commit'

    when "abort"
      if object instanceof Array
        objects = object
      else
        objects = [object]

      dbName = objects[0].database
      IndexedDBBackbone._getDriver(dbName).execute null, 'abort'

    else
      IndexedDBBackbone._getDriver(object.database).execute object.storeName, method, object, options

if (typeof exports == 'undefined')
  Backbone.ajaxSync = Backbone.sync
  Backbone.sync = IndexedDBBackbone.sync
else
  exports.sync = IndexedDBBackbone.sync

# window.addEventListener "unload", () ->
#   Backbone.sync("closeall")

