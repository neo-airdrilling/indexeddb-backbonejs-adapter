class window.Driver
  constructor: (schema, ready, nolog) ->
    @schema = schema
    @ready = ready
    @error = null
    @transactions = [] # Used to list all transactions and keep track of active ones.
    @db = null
    @nolog = nolog
    @supportOnUpgradeNeeded = false

    @lastMigrationPathVersion = _.last(schema.migrations).version

    @launchMigrationPath = (dbVersion) ->
      clonedMigrations = _.clone(schema.migrations)
      @migrate clonedMigrations, dbVersion, {
          success: =>
            @ready()
          error: =>
            @error = "Database not up to date. #{dbVersion} expected was #{@lastMigrationPathVersion}"
      }

    debugLog "opening database", schema.id, "in version #", @lastMigrationPathVersion unless @nolog
    @dbRequest = indexedDB.open(schema.id, @lastMigrationPathVersion) # schema version need to be an unsigned long

    @dbRequest.onblocked = (e) =>
      debugLog("blocked") unless @nolog

    @dbRequest.onsuccess = (e) =>
      @db = e.target.result # Attach the connection ot the queue.
      if !@supportOnUpgradeNeeded
        currentIntDBVersion = (parseInt(@db.version, 10) ||  0) # we need convert beacuse chrome store in integer and ie10 DP4+ in int
        lastMigrationInt = (parseInt(lastMigrationPathVersion, 10) || 0)  # And make sure we compare numbers with numbers.

        if (currentIntDBVersion == lastMigrationInt) # if support new event onupgradeneeded will trigger the ready function
          # No migration to perform!
          @ready()
        else if (currentIntDBVersion < lastMigrationInt )
          # We need to migrate up to the current migration defined in the database
          @launchMigrationPath(currentIntDBVersion)
        else
          # Looks like the IndexedDB is at a higher version than the current driver schema.
          @error = "Database version is greater than current code " + currentIntDBVersion + " expected was " + lastMigrationInt

    @dbRequest.onerror = (e) =>
      # Failed to open the database
      @error = "Couldn't not connect to the database"

    @dbRequest.onabort = (e) =>
      # Failed to open the database
      @error = "Connection to the database aborted"

    @dbRequest.onupgradeneeded = (iDBVersionChangeEvent) =>
      @db = iDBVersionChangeEvent.target.transaction.db

      @supportOnUpgradeNeeded = true

      debugLog("onupgradeneeded = #{iDBVersionChangeEvent.oldVersion} => #{iDBVersionChangeEvent.newVersion}") if (!@nolog)
      @launchMigrationPath(iDBVersionChangeEvent.oldVersion)

  close: () ->
    if @db? then @db.close()

  # Performs all the migrations to reach the right version of the database.
  migrate: (migrations, version, options) ->
    debugLog("Starting migrations from ", version) unless @nolog
    @_migrate_next(migrations, version, options)

  # Performs the next migrations. This method is private and should probably not be called.
  _migrate_next: (migrations, version, options) ->
    debugLog("_migrate_next begin version from #" + version) unless @nolog
    that = this
    migration = migrations.shift()
    if (migration)
      if (!version || version < migration.version)
        # We need to apply this migration-
        if (typeof migration.before == "undefined")
          migration.before = (next) ->
            next()
        if (typeof migration.after == "undefined")
          migration.after = (next) ->
            next()
        # First, let's run the before script
        debugLog("_migrate_next begin before version #" + migration.version) unless @nolog
        migration.before () =>
          debugLog("_migrate_next done before version #" + migration.version) unless @nolog

          continueMigration = (e) =>
            debugLog("_migrate_next continueMigration version #" + migration.version) unless @nolog

            transaction = @dbRequest.transaction || versionRequest.result
            debugLog("_migrate_next begin migrate version #" + migration.version) unless @nolog

            migration.migrate transaction, () =>
              debugLog("_migrate_next done migrate version #" + migration.version) unless @nolog
              # Migration successfully appliedn let's go to the next one!
              debugLog("_migrate_next begin after version #" + migration.version) unless @nolog
              migration.after () =>
                debugLog("_migrate_next done after version #" + migration.version) unless @nolog
                debugLog("Migrated to " + migration.version) unless @nolog

                #last modification occurred, need finish
                if (migrations.length == 0)
                  # if @supportOnUpgradeNeeded
                  #   debugLog("Done migrating") unless @nolog
                  #   # No more migration
                  #   options.success()
                  # else
                    debugLog("_migrate_next setting transaction.oncomplete to finish  version #" + migration.version) unless @nolog
                    transaction.oncomplete = () =>
                      debugLog("_migrate_next done transaction.oncomplete version #" + migration.version) unless @nolog

                      debugLog("Done migrating") unless @nolog
                      # No more migration
                      options.success()
                else
                  debugLog("_migrate_next setting transaction.oncomplete to recursive _migrate_next  version #" + migration.version) unless @nolog
                  transaction.oncomplete = () =>
                    debugLog("_migrate_next end from version #" + version + " to " + migration.version) unless @nolog
                    that._migrate_next(migrations, version, options)

          if !@supportOnUpgradeNeeded
            debugLog("_migrate_next begin setVersion version #" + migration.version) unless @nolog
            versionRequest = @db.setVersion(migration.version)
            versionRequest.onsuccess = continueMigration
            versionRequest.onerror = options.error
          else
            continueMigration()
      else
        # No need to apply this migration
        debugLog("Skipping migration " + migration.version) unless @nolog
        @_migrate_next(migrations, version, options)

