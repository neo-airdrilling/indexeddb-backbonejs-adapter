# Method used by Backbone for sync of data with data store. It was initially designed to work with "server side" APIs, This wrapper makes
# it work with the local indexedDB stuff. It uses the schema attribute provided by the object.
# The wrapper keeps an active Executuon Queue for each "schema", and executes querues agains it, based on the object type (collection or
# single model), but also the method... etc.
# Keeps track of the connections
IndexedDBBackbone.Databases = {}
IndexedDBBackbone._schemas = {}

IndexedDBBackbone.describe = (dbName) ->
  IndexedDBBackbone._schemas[dbName] = IDBSchema.describe(dbName)

IndexedDBBackbone.sync = (method, object, options) ->
  Databases = IndexedDBBackbone.Databases

  if (method=="closeall")
    _.each Databases, (database) ->
      database.close()
    # Clean up active databases object.
    Databases = {}
    return

  schema = IndexedDBBackbone._schemas[object.database]
  if (Databases[schema.id])
    if (Databases[schema.id].version != _.last(schema.migrations).version)
      Databases[schema.id].close()
      delete Databases[schema.id]

  Databases[schema.id] ||= new IndexedDBBackbone.ExecutionQueue(schema, schema.nolog)
  Databases[schema.id].execute([method, object, options])

if (typeof exports == 'undefined')
  Backbone.ajaxSync = Backbone.sync
  Backbone.sync = IndexedDBBackbone.sync
else
  exports.sync = IndexedDBBackbone.sync

# window.addEventListener "unload", () ->
#   Backbone.sync("closeall")

