# Standardize naming across browsers
IndexedDBBackbone.indexedDB = window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB || window.msIndexedDB
IndexedDBBackbone.IDBTransaction = window.IDBTransaction || window.webkitIDBTransaction || { READ_WRITE: "readwrite" }
IndexedDBBackbone.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange
IndexedDBBackbone.IDBCursor = window.IDBCursor || window.webkitIDBCursor ||  window.mozIDBCursor ||  window.msIDBCursor

