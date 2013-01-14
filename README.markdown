This is an [IndexedDB](http://www.w3.org/TR/IndexedDB/) adapter for [Backbone.js](http://documentcloud.github.com/backbone/).

# Usage

We're using the legendary TodoMVC app to demonstrate the use of our adapter. Code can be found in `examples/todo/` folder.

### 1. Defining your Schema

You will need to include `gen/indexeddb-backbone.js` in your project and define a schema.

    IndexedDBBackbone.describe('todos-database')
      .createStore('todos', keyPath: 'id')

The above code defines a database named `todos-database`.

### 2. Using Backbone with indexedDB

In your Backbone models and collections, specify 2 more attributes: `database` and `storeName`.

    app.Todos = Backbone.Collection.extend({
      database: 'todos',
      storeName: 'todos',
      ...
    });

    app.Todo = Backbone.Model.extend({
      database: 'todos',
      storeName: 'todos',
      ...
    });

That's all. Your app now uses `IndexedDB` for storage.  
Opening up `Resources` tab in `Developer Tools` in Chrome, refresh your IndexedDB and you should see something similar to this:

*Image

### 3. Transactions

Make use of `Transactions`!  
Let's take a look at this classic transaction use example:

    Backbone.transaction([accounts], function(){
      accountA.withdraw(amount);
      accountB.deposit(amount);

      if (something_goes_wrong){
        return false; // this rollbacks the transaction
      } else {
        return true; // this commits the transaction
      }
    }, {
      success: function(e){
        // successful
      },
      error: function(e){
        // something went wrong. everything's rollbacked. $ stay where it was.
      },
      abort: function(e){
        // everything's rollbacked. $ stay where it was.
      }
    });

`Backbone.transaction(objects, run, options)`  

+ objects: an array of Backbone.Model or Backbone.Collection to know how many object stores it needs to touch.
+ run: a function enclosing all the operations you want to run in the transaction.
+ options: callbacks for `success`, `error` and `abort`.

# Browser support and limitations

# Contributing

### Tests

We use [Jasmine](http://pivotal.github.com/jasmine/) as our test framework.
Specs are written in CoffeeScript in `spec/` folder. To generate spec, run `cake spec`.
Open SpecRunner.html to run the specs.

### Contributing

Components of adapter are written in CoffeeScript in `src/`. `cake watch` watches changes made to this folder and `spec/` and compiles to Javascript in `gen/`.  

# Credits

This project started as a fork from [superfeedr/indexeddb-backbonejs-adapter](https://github.com/superfeedr/indexeddb-backbonejs-adapter).

