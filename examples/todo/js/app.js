var app = app || {};
var ENTER_KEY = 13;

$(function() {

  IndexedDBBackbone.describe('todos')
    .createStore('todos', { keyPath: 'id' });

  // Kick things off by creating the **App**.
  new app.AppView();

});
