# Standardize naming across browsers
IndexedDBBackbone.indexedDB = window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB || window.msIndexedDB

IndexedDBBackbone.IDBTransaction = {
  READ_WRITE: "readwrite"
  READ_ONLY: "readonly"
}

IndexedDBBackbone.IDBKeyRange = window.IDBKeyRange || window.webkitIDBKeyRange

IndexedDBBackbone.IDBCursor = window.mozIDBCursor || window.msIDBCursor || {
  PREV: "prev"
  PREV_NO_DUPLICATE: "prevunique"
  NEXT: "next"
  NEXT_NO_DUPLICATE: "nextunique"
}

