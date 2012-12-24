// Naming is a mess!
var indexedDB = window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB || window.msIndexedDB ;
var IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || { READ_WRITE: "readwrite" }; // No prefix in moz
var IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange ; // No prefix in moz

window.IDBCursor = window.IDBCursor || window.webkitIDBCursor ||  window.mozIDBCursor ||  window.msIDBCursor ;

