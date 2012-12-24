# Method used by Backbone for sync of data with data store. It was initially designed to work with "server side" APIs, This wrapper makes
# it work with the local indexedDB stuff. It uses the schema attribute provided by the object.
# The wrapper keeps an active Executuon Queue for each "schema", and executes querues agains it, based on the object type (collection or
# single model), but also the method... etc.
# Keeps track of the connections
Databases = {}

sync = (method, object, options) ->

  if (method=="closeall")
    _.each Databases, (database) ->
      database.close()
    # Clean up active databases object.
    Databases = {}
    return

  schema = object.database
  if (Databases[schema.id])
    if (Databases[schema.id].version != _.last(schema.migrations).version)
      Databases[schema.id].close()
      delete Databases[schema.id]

  next = () ->
    Databases[schema.id].execute([method, object, options])

  if (!Databases[schema.id])
    Databases[schema.id] = new ExecutionQueue(schema,next,schema.nolog)
  else
    next()

if (typeof exports == 'undefined')
  Backbone.ajaxSync = Backbone.sync
  Backbone.sync = sync
else
  exports.sync = sync

# window.addEventListener "unload", () ->
#   Backbone.sync("closeall")

