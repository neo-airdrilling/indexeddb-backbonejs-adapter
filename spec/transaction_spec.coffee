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

      success1 = jasmine.createSpy()
      success2 = jasmine.createSpy()
      success3 = jasmine.createSpy()
      success4 = jasmine.createSpy()
      success5 = jasmine.createSpy()
      success6 = jasmine.createSpy()

      Backbone.transaction [kenshin, torrent],
        ->
          #create
          theWall.save undefined,
            success: success1
          kenshin.save undefined,
            success: success2
          torrent.save undefined,
            success: success3
          #update
          theWall.save { name: 'UPDATED' },
            success: success4
          #destroy
          theWall.destroy
            success: success5

        success: ->
          expect(success1).toHaveBeenCalled()
          expect(success2).toHaveBeenCalled()
          expect(success3).toHaveBeenCalled()
          expect(success4).toHaveBeenCalled()
          expect(success5).toHaveBeenCalled()

          new Theater().fetch
            success: (movies) ->
              expect(movies.length).toEqual 1

              new PirateBay().fetch
                success: (torrents) ->
                  expect(torrents.length).toEqual 1
                  testDone()

  it "rolls back the transaction when it returns false", ->
    asyncTest ->
      Backbone.transaction [kenshin],
        ->
          theWall.save()

      Backbone.transaction [kenshin],
        ->
          kenshin.save()
          false
        abort: (e) ->
          movies = new Theater()
          movies.fetch
            success: (e) ->
              expect(movies.length).toEqual 1
              expect(movies.first().get('name')).toEqual "The Wall"
              testDone()
        error: (e) ->
          fail('Not me, said the duck!')

  it "rolls back the transaction when errors occur", ->
    asyncTest ->
      Backbone.transaction [kenshin],
        ->
          theWall.save()
          torrent.save()
          true

        error: (e) ->
          movies = new Theater()
          movies.fetch
            success: (e) ->
              expect(movies.length).toEqual 0
              testDone()

