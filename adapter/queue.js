// ExecutionQueue object
// The execution queue is an abstraction to buffer up requests to the database.
// It holds a "driver". When the driver is ready, it just fires up the queue and executes in sync.
function ExecutionQueue(schema,next,nolog) {
    this.driver     = new Driver(schema, this.ready.bind(this), nolog);
    this.started    = false;
    this.stack      = [];
    this.version    = _.last(schema.migrations).version;
    this.next = next;
}

// ExecutionQueue Prototype
ExecutionQueue.prototype = {
    // Called when the driver is ready
    // It just loops over the elements in the queue and executes them.
    ready: function () {
        this.started = true;
        _.each(this.stack, function (message) {
            this.execute(message);
        }.bind(this));
        this.next();
    },

    // Executes a given command on the driver. If not started, just stacks up one more element.
    execute: function (message) {
        if (this.started) {
            this.driver.execute(message[1].storeName, message[0], message[1], message[2]); // Upon messages, we execute the query
        } else {
            this.stack.push(message);
        }
    },

    close : function(){
        this.driver.close();
    }
};

