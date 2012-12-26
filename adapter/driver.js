// Generated by CoffeeScript 1.4.0
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

window.Driver = (function() {

  function Driver(schema, ready, nolog) {
    this._migrate_next = __bind(this._migrate_next, this);

    this.migrate = __bind(this.migrate, this);

    var _this = this;
    this.schema = schema;
    this.ready = ready;
    this.error = null;
    this.transactions = [];
    this.db = null;
    this.nolog = nolog;
    this.logger = function() {
      var _ref;
      if (nolog) {
        if ((typeof window !== "undefined" && window !== null ? (_ref = window.console) != null ? _ref.log : void 0 : void 0) != null) {
          return window.console.log.apply(window.console, arguments);
        } else if ((typeof console !== "undefined" && console !== null ? console.log : void 0) != null) {
          return console.log(apply(console, arguments));
        }
      }
    };
    this.supportOnUpgradeNeeded = false;
    this.lastMigrationPathVersion = _.last(schema.migrations).version;
    this.launchMigrationPath = function(dbVersion) {
      var clonedMigrations,
        _this = this;
      clonedMigrations = _.clone(schema.migrations);
      return this.migrate(clonedMigrations, dbVersion, {
        success: function() {
          return _this.ready();
        },
        error: function() {
          return _this.error = "Database not up to date. " + dbVersion + " expected was " + _this.lastMigrationPathVersion;
        }
      });
    };
    this.logger("opening database", schema.id, "in version #", this.lastMigrationPathVersion);
    this.dbRequest = indexedDB.open(schema.id, this.lastMigrationPathVersion);
    this.dbRequest.onblocked = function(e) {
      return _this.logger("blocked");
    };
    this.dbRequest.onsuccess = function(e) {
      var currentIntDBVersion, lastMigrationInt;
      _this.db = e.target.result;
      if (!_this.supportOnUpgradeNeeded) {
        currentIntDBVersion = parseInt(_this.db.version, 10) || 0;
        lastMigrationInt = parseInt(lastMigrationPathVersion, 10) || 0;
        if (currentIntDBVersion === lastMigrationInt) {
          return _this.ready();
        } else if (currentIntDBVersion < lastMigrationInt) {
          return _this.launchMigrationPath(currentIntDBVersion);
        } else {
          return _this.error = "Database version is greater than current code " + currentIntDBVersion + " expected was " + lastMigrationInt;
        }
      }
    };
    this.dbRequest.onerror = function(e) {
      return _this.error = "Couldn't not connect to the database";
    };
    this.dbRequest.onabort = function(e) {
      return _this.error = "Connection to the database aborted";
    };
    this.dbRequest.onupgradeneeded = function(iDBVersionChangeEvent) {
      _this.db = iDBVersionChangeEvent.target.transaction.db;
      _this.supportOnUpgradeNeeded = true;
      if (!_this.nolog) {
        _this.logger("onupgradeneeded = " + iDBVersionChangeEvent.oldVersion + " => " + iDBVersionChangeEvent.newVersion);
      }
      return _this.launchMigrationPath(iDBVersionChangeEvent.oldVersion);
    };
  }

  Driver.prototype.close = function() {
    if (this.db != null) {
      return this.db.close();
    }
  };

  Driver.prototype.migrate = function(migrations, version, options) {
    this.logger("Starting migrations from ", version);
    return this._migrate_next(migrations, version, options);
  };

  Driver.prototype._migrate_next = function(migrations, version, options) {
    var migration, that,
      _this = this;
    this.logger("_migrate_next begin version from #" + version);
    that = this;
    migration = migrations.shift();
    if (migration) {
      if (!version || version < migration.version) {
        if (typeof migration.before === "undefined") {
          migration.before = function(next) {
            return next();
          };
        }
        if (typeof migration.after === "undefined") {
          migration.after = function(next) {
            return next();
          };
        }
        this.logger("_migrate_next begin before version #" + migration.version);
        return migration.before(function() {
          var continueMigration, versionRequest;
          _this.logger("_migrate_next done before version #" + migration.version);
          continueMigration = function(e) {
            var transaction;
            _this.logger("_migrate_next continueMigration version #" + migration.version);
            transaction = _this.dbRequest.transaction || versionRequest.result;
            _this.logger("_migrate_next begin migrate version #" + migration.version);
            return migration.migrate(transaction, function() {
              _this.logger("_migrate_next done migrate version #" + migration.version);
              _this.logger("_migrate_next begin after version #" + migration.version);
              return migration.after(function() {
                _this.logger("_migrate_next done after version #" + migration.version);
                _this.logger("Migrated to " + migration.version);
                if (migrations.length === 0) {
                  _this.logger("_migrate_next setting transaction.oncomplete to finish  version #" + migration.version);
                  return transaction.oncomplete = function() {
                    _this.logger("_migrate_next done transaction.oncomplete version #" + migration.version);
                    _this.logger("Done migrating");
                    return options.success();
                  };
                } else {
                  _this.logger("_migrate_next setting transaction.oncomplete to recursive _migrate_next  version #" + migration.version);
                  return transaction.oncomplete = function() {
                    _this.logger("_migrate_next end from version #" + version + " to " + migration.version);
                    return that._migrate_next(migrations, version, options);
                  };
                }
              });
            });
          };
          if (!_this.supportOnUpgradeNeeded) {
            _this.logger("_migrate_next begin setVersion version #" + migration.version);
            versionRequest = _this.db.setVersion(migration.version);
            versionRequest.onsuccess = continueMigration;
            return versionRequest.onerror = options.error;
          } else {
            return continueMigration();
          }
        });
      } else {
        this.logger("Skipping migration " + migration.version);
        return this._migrate_next(migrations, version, options);
      }
    }
  };

  return Driver;

})();