describe "Backbone.transaction", ->
  theWall = null
  kenshin = null
  torrent = null

  beforeEach ->
    theWall = new Movie(name: 'The Wall', year: 1973)
    kenshin = new Movie(name: 'Rurouni Kenshin', year: 2012)
    torrent = new Torrent(name: 'Transatlantic Sessions 1')

    asyncTest ->
      Backbone.sync 'delete', new Theater(), success: ->
        Backbone.sync 'delete', new PirateBay(), success: testDone

  it 'runs all operations in a transaction', ->
    asyncTest ->
      Backbone.transaction [kenshin, torrent], ->
        theWall.save()
        kenshin.save()
        torrent.save()

      movies = new Theater()
      torrents = new PirateBay()
      movies.fetch
        success: (e) ->
          expect(movies.length).toEqual 2

          torrents.fetch
            success: (e) ->
              console.debug 'gonna fail here', torrents.toArray()
              expect(torrents.length).toEqual 1
              testDone()

  it "rolls back the transaction when it returns false", ->
    asyncTest ->
      Backbone.transaction [kenshin], ->
        theWall.save()

      Backbone.transaction [kenshin], ->
        kenshin.save()
        false

      movies = new Theater()
      movies.fetch
        success: (e) ->
          expect(movies.length).toEqual 1
          expect(movies.first().get('name')).toEqual "The Wall"
          testDone()

  it "rolls back the transaction when errors occur", ->
    asyncTest ->
      try
        Backbone.transaction [kenshin], ->
          theWall.save()
          torrent.save()
          true
      catch error
        console.debug error

      movies = new Theater()
      movies.fetch
        success: (e) ->
          expect(movies.length).toEqual 0
          testDone()
