# ExecutionQueue object
# The execution queue is an abstraction to buffer up requests to the database.
# It holds a "driver". When the driver is ready, it just fires up the queue and executes in sync.
class IndexedDBBackbone.ExecutionQueue
  constructor: (schema,next,nolog) ->
    @driver   = new IndexedDBBackbone.Driver(schema, @ready.bind(@), nolog)
    @started  = false
    @stack    = []
    @version  = _.last(schema.migrations).version
    @next = next

  # Called when the driver is ready
  # It just loops over the elements in the queue and executes them.
  ready: () ->
    @started = true
    _.each @stack, (message) =>
      @execute(message)
    @next()

  # Executes a given command on the driver. If not started, just stacks up one more element.
  execute: (message) ->
    if (@started)
      @driver.execute(message[1].storeName, message[0], message[1], message[2]) # Upon messages, we execute the query
    else
      @stack.push(message)

  close : () ->
    @driver.close()

