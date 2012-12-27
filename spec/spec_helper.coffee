# databases
databasev1 = {
  id: "movies-database"
  description: "The database for the Movies"
  migrations: [{
    version: 1
    migrate: (transaction, next) ->
      store = transaction.db.createObjectStore("movies")
      next()
  }]
}

databasev2 = $.extend(true, {}, databasev1)
databasev2.migrations.push(
  {
    version: 2
    migrate: (transaction, next) ->
      store = undefined
      if(!transaction.db.objectStoreNames.contains("movies"))
        store = transaction.db.createObjectStore("movies")
      store = transaction.objectStore("movies")
      store.createIndex("titleIndex", "title", {
        unique: false
      })
      store.createIndex("formatIndex", "format", {
        unique: false
      })
      next()
  }
)

databasev3 = $.extend(true, {}, databasev2)
databasev3.migrations.push(
  {
    version: 3
    migrate: (transaction, next) ->
      store = transaction.db.createObjectStore("torrents", {keyPath: "id"})
      next()
  }
)

# Models
class window.Moviev1 extends Backbone.Model
  database: databasev1
  storeName: "movies"

window.Movie = Backbone.Model.extend({
  database: databasev2
  storeName: "movies"
})

window.Torrent = Backbone.Model.extend({
  database: databasev3
  storeName: "torrents"
})

window.Theater = Backbone.Collection.extend({
  database: databasev2
  storeName: "movies"
  model: Movie
})

window.testDone = -> window.asyncTestDone = true

window.asyncTest = (test) ->
  runs test
  waitsFor (-> window.asyncTestDone), "test to finish", 500

beforeEach ->
  window.asyncTestDone = false

window.deleteDB = (dbObj) ->
  try
    indexedDB = IndexedDBBackbone.indexedDB
    dbreq = indexedDB.deleteDatabase(dbObj.id)
    dbreq.onsuccess = (event) ->
      db = event.result
      console.log "indexedDB: " + dbObj.id + " deleted"

    dbreq.onerror = (event) ->
      console.error "indexedDB.delete Error: " + event.message
  catch e
    console.error "Error: " + e.message

    #prefer change id of database to start ont new instance
    dbObj.id = dbObj.id + "." + IndexedDBBackbone.guid()
    console.log "fallback to new database name :" + dbObj.id

deleteDB(databasev2)

window.fail = (msg) ->
  expect(true).toEqual(false)
  testDone()

window.addAllMovies = (movies, done) ->
  unless movies
    movies = [
      title: "Hello"
      format: "blueray"
      id: "1"
    ,
      title: "Bonjour"
      format: "dvd"
      id: "2"
    ,
      title: "Halo"
      format: "blueray"
      id: "3"
    ,
      title: "Nihao"
      format: "streaming"
      id: "4"
    ,
      title: "Ciao"
      format: "dvd"
      id: "5"
    ]
  movie = movies.shift()
  if movie
    m = new Movie()
    m.save movie,
      success: ->
        addAllMovies movies, done

      error: (o, error) ->
        start()
        equals true, false, error.error.target.webkitErrorMessage

  else
    done()

window.deleteNext = (movies, done) ->
  if movies.length is 0
    done()
  else
    movies[0].destroy success: ->
      deleteNext movies, done
