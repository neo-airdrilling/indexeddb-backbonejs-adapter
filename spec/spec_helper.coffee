# databases

DBNAME = "movies-database"

IndexedDBBackbone.describe(DBNAME)
  .createStore('movies')
  .createIndex('movies', 'titleIndex', 'title', unique: false)
  .createIndex('movies', 'formatIndex', 'format', unique: false)
  .createStore('torrents', keyPath: 'id')

# Models
class window.Moviev1 extends Backbone.Model
  database: DBNAME
  storeName: "movies"

window.Movie = Backbone.Model.extend({
  database: DBNAME
  storeName: "movies"
})

window.Torrent = Backbone.Model.extend({
  database: DBNAME
  storeName: "torrents"
})

window.Theater = Backbone.Collection.extend({
  database: DBNAME
  storeName: "movies"
  model: Movie
})

window.testDone = -> window.asyncTestDone = true

window.asyncTest = (test) ->
  window.asyncTestDone = false
  runs test
  waitsFor (-> window.asyncTestDone), "test to finish", 500

beforeEach ->
  window.asyncTestDone = false

window.deleteDB = (dbName) ->
  try
    indexedDB = IndexedDBBackbone.indexedDB
    dbreq = indexedDB.deleteDatabase(dbName)
    dbreq.onsuccess = (event) ->
      db = event.result
      console.log "indexedDB: " + dbName + " deleted"

    dbreq.onerror = (event) ->
      console.error "indexedDB.delete Error: " + event.message
  catch e
    console.error "Error: " + e.message

    #prefer change id of database to start ont new instance
    dbName = dbName + "." + IndexedDBBackbone.guid()
    console.log "fallback to new database name :" + dbName

deleteDB(DBNAME)

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