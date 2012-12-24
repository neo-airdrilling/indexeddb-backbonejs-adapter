(function () { /*global _: false, Backbone: false */
    // Method used by Backbone for sync of data with data store. It was initially designed to work with "server side" APIs, This wrapper makes
    // it work with the local indexedDB stuff. It uses the schema attribute provided by the object.
    // The wrapper keeps an active Executuon Queue for each "schema", and executes querues agains it, based on the object type (collection or
    // single model), but also the method... etc.
    // Keeps track of the connections
    var Databases = {};

    function sync(method, object, options) {

        if(method=="closeall"){
            _.each(Databases,function(database){
                database.close();
            });
            // Clean up active databases object.
            Databases = {}
            return;
        }

        var schema = object.database;
        if (Databases[schema.id]) {
            if(Databases[schema.id].version != _.last(schema.migrations).version){
                Databases[schema.id].close();
                delete Databases[schema.id];
            }
        }

        var next = function(){
            Databases[schema.id].execute([method, object, options]);
        };

        if (!Databases[schema.id]) {
              Databases[schema.id] = new ExecutionQueue(schema,next,schema.nolog);
            }else
        {
            next();
        }


    };

    if(typeof exports == 'undefined'){
        Backbone.ajaxSync = Backbone.sync;
        Backbone.sync = sync;
    }
    else {
        exports.sync = sync;
        exports.debugLog = debugLog;
    }

    //window.addEventListener("unload",function(){Backbone.sync("closeall")})
})();
