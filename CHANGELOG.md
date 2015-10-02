# Change Log
All notable changes to this project will be documented in this file.
This file should follow the standards specified on [http://keepachangelog.com/]
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased][unreleased]

### Fixed

- Context now set for Model.all QueryProxy so that logs can reflect that it wasn't just a raw Cypher query

### Added

- Support for Array arguments to ActiveRel's `from_class` and `to_class`.

### Changed

- Deprecated all methods in ActiveRel's Query module except for those that allow finding by id.
- Return `true` on successful `#save!` calls (Thanks to jmdeldin)

## [5.2.9] - 09-30-2015

### Fixed
- Better error message for `ActiveRel` creation when from_node|to_node is not persisted

## [5.2.8] - 09-30-2015

### Fixed
- Support `references` in model/scaffold generators

## [5.2.7] - 09-25-2015

### Fixed
- Allow for association `model_class` to be prepended with double colons

## [5.2.6] - 09-16-2015

### Fixed

- Fixed issue where caching an association causes further queries on the association to return the cached result

## [5.2.5] - 09-11-2015

### Fixed

- Regression in last release caused properties to revert to default on update if not present in the properties for update

### Added
- Type Converters were added for String, Integer, Fixnum, BigDecimal, and Boolean to provide type conversion for these objects in QueryProxy.
- `rel_where` will now use ActiveRel classes for type conversion, when possible.
- Converters will look for a `converted?` method to determine whether an object is of the appropriate type for the database. This allows converters to be responsible for multiple types, if required.

## [5.2.4] - 09-11-2015

### Fixed
- Use `debug` log level for query logging
- `updated_at` properties were not being added up `update` events, only updated.
- Default values of Boolean properties were not being set when `default: false`
- `props_for_update` was using String keys instead of Symbols, like `props_for_update`
- `props_for_create` and `props_for_update` were not adding default property values to the hash.
- ActiveNode's `merge` and `find_or_create` methods were not setting default values of declared properties when `ON CREATE` was triggered. The code now uses `props_for_create`.

## [5.2.3] - 09-07-2015

Added bugfixes from 5.1.4 and 5.1.5 that were missed in earlier 5.2.x releases:
- `AssociationProxy` now responds to `serializable_hash` so that `include` can be used in `render json` in Rails controllers
- Fixed errors when trying to call `#{association}_ids=` on an unpersisted node with UUIDs or an array thereof.
- Removed extra Cypher query to replace relationships when working with unpersisted nodes and association=.
- Bug related to Rails reloading an app and returning nodes without first reinitializing models, resulting in CypherNodes.

## [5.2.2] - 09-06-2015

### Fixed
- Fixed setting of association(_id|_ids) on .create

## [5.2.1] - 09-04-2015

### Fixed
- Now possible to configure `record_timestamps` with rails `config`

## [5.2.0] - 08-30-2015

### Added
- `props_for_persistence`, `props_for_create`, `props_for_update` instance methods for all nodes and rels. Each returns a hash with properties appropriate for sending to the database in a Cypher query to create or update an object.
- Added `record_timestamps` configuration do default all `ActiveNode` and `ActiveRel` models to have `created_at` and `updated_at` timestamps (from #939, thanks @rebecca-eakins)
- Added `timestamp_type` configuration to specify how timestamps should be stored (from #939, thanks @rebecca-eakins)

### Changed
- Methods related to basic node and rel persistence (`save`, `create_model`, `_create_node`, others) were refactored to make the processes simpler, clearer, and slightly faster.
- Unit test directory structure was rearranged to mirror the `lib` directory.

## [5.1.3] - 08-23-2015

### Fixed
- `has_one` associations are now properly cached (like `has_many` associations)
- `QueryProxy` now responds to `#to_ary`.  Fixes integration with ActiveModelSerializer gem


## [5.1.2] - 08-20-2015

### Fixed
- When association has `model_class` and `type: false` the association doesn't work (see: https://github.com/neo4jrb/neo4j/pull/930)

## [5.1.1] - 08-19-2015

### Fixed
- Fixed a bug where the `Neo4j::Timestamps` mixin was not able to be included

## [5.1.0.rc.3] - 08-17-2015

### Fixed
- Associations defined in ActiveNode models will delegate `unique?` to the model set in `rel_class`. This makes it easier for the rel class to act as the single source of truth for relationship behavior.

### Added
- ActiveRel: `#{related_node}_neo_id` instance methods to match CypherRelationship. Works with start/from and end/to.
- ActiveRel: `type` now has a new alias, `rel_type`. You might recognize this from the `(Cypher|Embedded)Relationship` class and ActiveNode association option.
- Contributing to the gem? Rejoice, for it now supports [Dotenv](https://github.com/bkeepers/dotenv).

## [5.1.0.rc.2] - 08-16-2015

### Added
- Ability to use `#where_not` method on `ActiveNode` / `QueryProxy`

## [5.1.0.rc.1] - 08-14-2015

### Fixed
- Added a `before_remove_const` method to clear cached models when Rails `reload!` is called. 5.0.1 included a workaround but this appears to cut to the core of the issue. See https://github.com/neo4jrb/neo4j/pull/855.
- To prevent errors, changing an index to constraint or constraint to index will drop the existing index/constraint before adding the new.
- Fixed `AssociationProxy#method_missing` so it properly raises errors.

### Added
- Added ability to view `model_class` from `Association` class for `rails_admin` Neo4j adapter
- QueryProxy `where` will now look for declared properties matching hash keys. When found, it will send the value through that property's type converter if the type matches the property's unconverted state.
- Improved handling of unpersisted nodes with associations. You can now use `<<` to create associations between unpersisted nodes. A `save` will cascade through unpersisted objects, creating nodes and rels along the way. See https://github.com/neo4jrb/neo4j/pull/871
- Support formatted cypher queries for easy reading by humans via the `pretty_logged_cypher_queries` configuration variable
- Ability to query for just IDs on associations
- On `QueryProxy` objects you can now use an `:id` key in `where` and `find_by` methods to refer to the property from `id_property` (`uuid` by default)
- Added `ActiveRel.creates_unique` and deprecated `ActiveRel.creates_unique_rel`
- Added #inspect method to ActiveRel to show Cypher-style representation of from node, to node, and relationship type
- Added `Neo4j::Timestamps`, `Neo4j::Timestamps::Created`, and `Neo4j::Timestamps::Updated` mixins to add timestamp properties to `ActiveNode` or `ActiveRel` classes

### Changed

- Methods related to ActiveNode's IdProperty module were refactored to improve performance and simplify the API. Existing `default_properties` methods were reworked to reflect their use as-implemented: storage for a single default property, not multiple.
- Implementation adjustments that improve node and rel initialization speed, particularly when loading large numbers of objects from the database.

## [5.0.15] - 08-12-2015

### Fixed

- `reload!` within Rails apps will work correctly. An earlier release included a workaround but this uses ActiveModel's system for clearing caches to provide a more thorough resolution.

## [5.0.14] - 08-09-2015

### Fixed

- Calling `all` on a QueryProxy chain would cause the currently set node identity within Cypher to be lost.

## [5.0.13] - 08-07-2015

### Fixed
- Backport AssociationProxy#method_missing fix to raise errors on invalid methods
- Fix the count issue on depth two associations (#881)

## [5.0.12] - ?

### Fixed
- Break between associations so that potential `where` clauses get applied to the correct `(OPTIONAL )MATCH` clause

### Fixed
- Delegate `first` and `last` from `AssociationProxy` to `QueryProxy`
- Fix `order` behavior for `first` and `last` in `QueryProxy`

## [5.0.11] - ?

### Fixed
- Delegate `first` and `last` from `AssociationProxy` to `QueryProxy`
- Fix `order` behavior for `first` and `last` in `QueryProxy`

## [5.0.10] - 2015-07-31

### Fixed
- Fix what should have been a very obvious bug in `_active_record_destroyed_behavior` behavior
- Add eager loading to QueryProxy so that it works in all expected places

## [5.0.9] - 2015-07-29

### Fixed
- "NameError: uninitialized constant Class::Date" (https://github.com/neo4jrb/neo4j/issues/852)

## [5.0.8] - 2015-07-26

### Changed
- Copied QueryClauseMethods doc from master

## [5.0.7] - 2015-07-26

### Changed
- Copied `docs` folder from master because a lot of work had gone into the docs since 5.0.0 was released

## [5.0.6] - 2015-07-22

### Fixed
- Fix query logging so that by default it only outputs to the user in the console and development server.  Logger can be changed with `neo4j.config.logger` configuration option

## [5.0.5] - 2015-07-19

### Added
- Added `log_cypher_queries` configuration option so that queries aren't on by default but that they can be controlled

## [5.0.4] - 2015-07-17

### Fixed
- Fixed bug which caused `QueryProxy` context to repeat (showed up in query logging)

## [5.0.3] - 2015-07-14

### Changed
- Moved `#with_associations` method from `AssociationProxy` to `QueryProxy` so that all `QueryProxy` chains can benefit from it.
- Added `_active_record_destroyed_behavior` semi-hidden configuration variable so that behavior for `ActiveNode#destroyed?` and `ActiveRel#destroyed?` can be changed to upcoming 6.0.0 behavior (matching ActiveRecord) where the database is not accessed.

## [5.0.2] - 2015-06-30

### Fixed
- Fix error when calling `#empty?` or `#blank?` on a query chain with on `order` specified
- Make `#find_each` and `#find_in_batches` return the actual objects rather than the result objects
- Query logging on console should be to STDOUT with `puts`.  Using `Rails.logger` outputs to the file in the `log` directory
- Modified queryproxy include? to accept a uuid instead of full node

## [5.0.1] - 2015-06-23

### Fixed
- Longstanding bug that would prevent association changes (`<<` and ActiveRel.create) in Rails after `reload!` had been called, see https://github.com/neo4jrb/neo4j/pull/839
- ActiveNode#inspect wasn't displaying the id_property
- Default property values and magic typecasting not being inherited correctly

### Changed
- In the absense of a `model_class` key, associations defined in ActiveNode models will use `from_/to_class` defined in `rel_class` to find destination. (Huge thanks to @olance, #838)
- ActiveRel's DSL was made a bit friendlier by making the `type`, `from_class` and `to_class` methods return their set values when called without arguments.
- Reworked ActiveRel's wrapper to behave more like ActiveNode's, removing some duplicate methods and moving others to Neo4j::Shared, resulting in a big performance boost when returning large numbers of rels.
- Updated gemspec to require neo4j-core 5.0.1+

### Added
- ActiveRel was given `find_or_create_by`, usable across single associations.

## [5.0.0] - 2015-06-18

### Fixed
- Prevented `to_key` from requiring an extra DB query. (See https://github.com/neo4jrb/neo4j/pull/827)

### Added
- QueryProxy associations accept `labels: false` option to prevent generated Cypher from using labels.

### Changed
- Properties explicitly set to type `Time` will no longer be converted to `DateTime`.

## [5.0.0.rc.3] - 2015-06-07

### Fixed
- Associations now allow `unique` option.  Error handling is generalized to make this testable (Thanks to @olance, see #824)

## [5.0.0.rc.2] - 2015-05-20

### Changed
- Set Ruby version requirement back to 1.9.3 because of problems with JRuby

## [5.0.0.rc.1] - 2015-05-20

### Changed
- Ruby 2.0.0 now required (>= 2.2.1 is recommended)
- All `ActiveNode` associations now require either a `type`, `origin`, or `rel_class` option.  Only one is allowed
- Defining associations will fail if unknown options are used (#796)
- `Model#find` fails if no node found (`Model#find_by` available when `nil` result desired) (#799)
- `#find_or_create` and `#merge` model class methods have been added
- Ensuring that all model callbacks are happening within transactions
- Major refactoring using `rubocop` with a lot of focus on speed improvements
- Specifically when loading many nodes at once we've measured 3x speed improvements

### Fixed
- `#find` on `QueryProxy` objects now does a model `find` rather than an `Enumerable` find
- Subclassed model classes now both create and query against it's ancestor's labels in addition to it's own (#690)
- `#first` and `#last` now work property when precedend by an `#order` in a `QueryProxy` chain (#720)
- `#count` when called after `#limit` will be performed within the bounds of limit specified

### Added
- Eager Loading is now supported!  See: [http://neo4jrb.readthedocs.org/en/latest/ActiveNode.html#eager-loading]
- Associations now return `AssociationProxy` objects (which are `Enumerable`) which have convenient `#inspect` methods for cleaner viewing in the Ruby console
- `model_class` key on associations now supports an Array (#589)
- When using `all` inside of a class method an argument for the node name can now be passed in (#737)
- Query(Proxy) syntax of `where("foo = ?", val)` and `where("foo = {bar}", bar: val)` now supported (#675)
- `module_handling` config option now available to control how class module namespaces translate to Neo4j labels (#753) (See: [http://neo4jrb.readthedocs.org/en/latest/Configuration.html])
- `#id_property` method has new `constraints` option to disable automatic uuid constraint (#738/#736)

(There are probably other changes too!)

**Changes above this point should conform to [http://keepachangelog.com/]**

## [4.1.2]
- Fixes two bugs related to inheritance: one regarding ActiveRel classes and relationship types, the other regarding ActiveNode primary_key properties not being set when a model is loaded prior to Neo4j session.

## [4.1.1]
- Switches use of Fixnum to Integer to improve 32-bit support

## [4.1.0]
This release includes many performance fixes and new features. The most notable:
- Huge stylist cleanup/refactoring by Brian on the entire gem by Brian armed with Rubocop. See http://neo4jrb.io/blog/2014/12/29/stay-out-of-trouble.html.
- Every node create, update, and destroy is now wrapped in a transaction. See http://neo4jrb.io/blog/2015/01/06/transactions_everywhere.html.
- New `dependent` options for associations: `:delete`, `:destroy`, `:delete_orphans`, `:destroy_orphans`. See http://neo4jrb.io/blog/2015/01/07/association_dependent_options.html.
- New `unique: true` option for associations, `creates_unique_rel` class method for ActiveRel. Both of these will result in relationship creation Cypher using "CREATE UNIQUE" instead of "CREATE".
- Fixed an n+1 query issue during node creation and update.
- Dieter simplified some code related to frozen attributes. See https://github.com/neo4jrb/neo4j/pull/655.
We now have a new website online at http://neo4jrb.io! Keep an eye on it for news and blogs related to this and other projects.

## [4.0.0]
- Change neo4j-core dependency from 3.1.0 to 4.0.0.

## [4.0.0.rc.4]
- _classname property is disabled by default for ActiveRel! It had been disabled for ActiveNode, this just evens the score.
- Fixes a bug to create better `result` labels in Cypher.
- Made the `delete_all` and `destroy_all` ActiveNode class methods consistent with their ActiveRecord counterparts. `destroy_all` previously performed its deletes in Cypher but it should have been returning nodes to Ruby and calling `destroy`. `delete_all` didn't exist at all.

## [4.0.0.rc.3]
Released minutes after rc.2 to catch one late addition!
- Adds serialization support for QueryProxy.

## [4.0.0.rc.2]
This release builds on features introduced in the first RC. We are releasing this as another RC because the API may be tweaked before release.
- New `proxy_as` for Core::Query to build QueryProxy chains onto Core::Query objects!
- Using `proxy_as`, new `optional` method in QueryProxy to use the `OPTIONAL MATCH` Cypher function.
- `match_to` and methods that depend on it now support arrays of nodes or IDs.
- New `rels_to`/`all_rels_to` methods.
- New `delete` and `destroy` methods in QueryProxy to easily remove relationships.
- Serialized objects will include IDs by default.

## [4.0.0.rc.1]
This release introduces API changes that may be considered breaking under certain conditions. See See https://github.com/neo4jrb/neo4j/wiki/Neo4j.rb-v4-Introduction.
Please use https://github.com/neo4jrb/neo4j/issues for support regarding this update! You can also reach us on Twitter: @neo4jrb (Brian) and @subvertallmedia (Chris).
- Default behavior changed: relationship types default to all caps, no prepending of "#". This behavior can be changed.
- ActiveRel models no longer require explicit calling of `type`. When missing, the model will infer a type using the class name following the same rules used to determine automatic relationship types from ActiveNode models.
- _classname properties will not be added automatically if you are using a version Neo4j >= 2.1.5. Instead, models are found using labels or relationship type. This is a potentially breaking change, particularly where ActiveRel is concerned. See the link at the beginning of this message for the steps required to work around this.
- Query scopes are now chainable! Call `all` at the start of your scope or method to take advantage of this.
- Changes required for Neo4j 2.2.
- Support for custom typecasters.
- New method `rel_where`, expanded behavior of `match_to` and `first_rel_to`
- Implemented ActiveSupport load hooks.
- Assorted performance improvements and refactoring.

## [3.0.4]
- Gemspec requires the latest neo4j-core.
- Fixed a pagination bug — thanks, @chrisgogreen!
- New QueryProxy methods `match_to` and `first_rel_to` are pretty cool.
- include_root_in_json is now configurable through config.neo4j.include_root_in_json or Neo4j::Config[:include_root_in_json]. Also cool.
- There's a new `delete_all` method for QueryProxy, too.
- @codebeige removed the `include?` class method, which was smart.
- Did I mention we won an award from Neo Tech? Check it out. https://github.com/neo4jrb/neo4j#welcome-to-neo4jrb

## [3.0.3]
- Gemspec has been updated to require neo4j-core 3.0.5
- Added `find_in_batches`
- Pagination has been updated to allow better ordering. Relaunch of neo4j-will_paginate as neo4j-will_paginate_redux is imminent!
- Everything is better: `create`'s handling of blocks, better behavior from `count`, better ActiveRel from_class/to_class checks, better handling of rel_class strings, and more
- Added a new find_or_create_by class method

Big thanks to new contributors Miha Rekar and Michael Perez! Also check out or Github issues, where we're discussing changes for 3.1.0. https://github.com/neo4jrb/neo4j/issues

## [3.0.2]
- "Model#all" now evaluates lazily, models no longer include Enumerable
- Faster, more efficient uniqueness validations
- Adjusted many common queries to use params, will improve performance
- ActiveRel fixes: create uses Core Query instead of Core's `rels` method, `{ classname: #{_classname} }` no longer inserted into every query, find related node IDs without loading the nodes
- Allow inheritance when checking model class on a relation (Andrew Jones)
- Provided migrations will use Rake.original_dir instead of Rails.env to provide better compatibility with frameworks other than Rails
- rel_class option in ActiveNode models will now accept string of a model name
- Additional bug fixes

## [3.0.1]
- Removed reference to neo4j-core from Gemfile and set neo4j.gemspec to use neo4j-core ~>3.0.0

## [3.0.0]
No change from rc 4

## [3.0.0.rc.4]
- UUIDs are now automatically specified on models as neo IDs won't be reliable
in future versions of neo4j
- Migrations now supported (including built-in migrations to migrate UUIDs and
insert the _classname property which is used for performance)
- Association reflection
- Model.find supports ids/node objects as well as arrays of id/node objects
- rake tasks now get automatically included into rails app


## [3.0.0.rc.3]
- thread safety improvements
- scope and general refactoring
- Added ability to create relationships on init (persisted on save)

## [3.0.0.rc.2]
- Use newer neo4j-core release

## [3.0.0.rc.1]
- Support for count, size, length, empty, blank? for has_many relationship
- Support for rails logger of cypher queries in development
- Support for distinct count
- Optimized methods: https://github.com/andreasronge/neo4j/wiki/Optimized-Methods
- Queries should respect mapped label names (#421)
- Warn if no session is available
- Fix broken == and equality (#424)

## [3.0.0.alpha.11]
- Bug fixes

## [3.0.0.alpha.10]
- ActiveRel support, see Wiki pages (chris #393)

## [3.0.0.alpha.9]
- Complete rewrite of the query api, see wiki page (#406, chris, brian)
- Performance improvements (#382,#400, #402, chris)
- idproperty - user defined primary keys (#396,#389)
- Reimplementation of Neo4j::Config
- Serialization of node properties (#381)
- Better first,last syntax (#379)

## [3.0.0.alpha.8]
- Integration with new Query API from neo4j-core including:
- - .query_as and #query_as methods to get queries from models (#366)
- - .qq method for QuickQuery syntax ( https://github.com/andreasronge/neo4j/wiki/Neo4j-v3#quickquery-work-in-progress / #366)
- Before and after callbacks on associations (#373)
- .find / .all / .count changed to be more like ActiveRecord
- .first / .last methods (#378)
- .find_by / .find_by! (#375)

## [3.0.0.alpha.7]
- Bug fix uniqueness-validator (#356 from JohnKellyFerguson)
- Many improvements, like update_attributes and validation while impl orm_adapter, Brian Underwood
- Impl orm_adapter API for neo4j so it can be used from for example devise, Brian Underwood (#355)
- Fix of inheritance of Neo4j::ActiveNode (#307)
- Expose add_label, and remove_label (#335)
- Fixed auto loading of classes bug, (#349)
- Bumped neo4j-core, 3.0.0.alpha.16

## [3.0.0.alpha.6]
- Support for Heroku URLs, see wiki https://github.com/andreasronge/neo4j/wiki/Neo4j-v3 (#334)

## [3.0.0.alpha.5]
- Added allow session options via 'config.neo4j.session_options' so it can run on heroku (#333)
- Relaxed Dependencies for Rails 4.1 (#332)
- Using neo4j-core version 3.0.0.alpha.12

## [3.0.0.alpha.4]
- Implemented validates_uniqueness_of (#311)
- Using neo4j-core version 3.0.0.alpha.11

## [3.0.0.alpha.3]
- Support for rails scaffolds
- Support for created_at and updated_at (#305)
- Support for ability to select a session to use per model (#299)
- BugFix: updating a model should not clear out old properties (#296)

## [3.0.0.alpha.2]
- Support for both embedded (only JRuby) and server API (runs on MRI Ruby !)
- Simple Rails app now work
- Support for has_n and has_one method
- ActiveModel support, callback, validation
- Declared properties (via active_attr gem)

## [2.3.0 / 2013-07-18]
- Fix Issue with HA console when ruby-debug is loaded (#261, thekendalmiller)
- Use 1.9 Neo4j

## [2.2.4 / 2013-05-19]
- get_or_create should return wrapped ruby nodes, alex-klepa, #241, #246
- Make sure freeze does not have side effects, #235
- Fix for carrierwave-neo4j (attribute_defaults), #235

## [2.2.3 / 2012-12-28]
- Support for HA cluster with neo4j 1.9.X, #228, #99, #223
- Make sure the Identity map is cleared after an exception, #214
- Relationship other_node should return wrapped node, #226
- Automatically convert DateTimes to UTC, (neo4j-wrapper #7)
- get_or_create should return a wrapped node (neo4j-wrapper #8)
- Make it work with Neo4j 1.7.1 (neo4j-core, #19)

## [2.2.2 - skipped]

## [2.2.1 / 2012-12-18]
- Fix for JRuby 1.7.1 and Equal #225
- Fix for create nodes and relationship using Cypher (neo4j-core #17)

## [2.2.0 / 2012-10-02]
- Using neo4j-cypher gem (1.0.0)
- Fix of neo4j-core configuration issue using boolean values #218
- Fixed RSpec issue on JRuby 1.7.x #217
- Aliased has_many to has_n, #183

## [2.2.0.rc1 / 2012-09-21]
- Use neo4j-core and neo4j-wrapper version 2.2.0.rc1
- Use the neo4j-cypher gem
- Better support for Orm Adapter, #212
- Use Cypher query when finder method does not have a lucene index, #210

## [2.0.1 / 2012-06-06]
- Use neo4j-core and neo4j-wrapper version 2.0.1

## [2.0.0 / 2012-05-07]
  (same as rc2)

## [2.0.0.rc2 / 2012-05-04]
- Enable Identity Map by default
- Added versioning for Neo4j::Core

## [2.0.0.rc1 / 2012-05-03]
- Fix of rake task to upgrade to 2.0
- Various Cypher DSL improvements, core(#3,#4,#5), #196
- Added Neo4j::VERSION

## [2.0.0.alpha.9 / 2012-04-27]
- Fix for rails scaffold generator

## [2.0.0.alpha.8 / 2012-04-27]
- Fix for "relationship to :all assigned twice for single instance" #178
- Fix for callback fire more then once (=> performance increase) #172
- Support for lucene search on array properties, #118
- Support for creating unique entities (get_or_create) #143
- Support for specifying has_n/has_one relationship with Strings instead of Class #160
- Support for serializer of hash and arrays on properties #185
- Fix for Neo4j::Rails::Relationship default property, #195
- Added support for pagination, see the neo4j-will_paginate gem
- Fixed Rails generators
- Added Cypher DSL support for is_a?
- Fix for "write_attribute persistes, contrary to AR convention" closes #182

## [2.0.0.alpha.7 / 2012-04-19]
- fix for Neo4j::Config bug - did not work from rails to set the db location, closes #191
- has_n and has_one method generate class method returning the name of the relationship as a Symbol, closes #170
- Raise exception if trying to index boolean property, closes #180
- Made start_node= and end_node= protected closes 186
- Support for things like @dungeon.monsters.dangerous { |m| m[:weapon?] == 'sword' } closes #181

## [2.0.0.alpha.6 / 2012-04-15]
- Complete rewrite and smaller change of API + lots of refactoring and better RSpecs
- Moved code to the neo4j-core and neo4j-wrapper gems
- Changed API - index properties using the Neo4j::Rails::Model (property :name, :index => :exact)
- Changed API - rel_type always returns a Symbol
- Changed API - #rels and #rel first parameter is always :outgoing, :incoming or :both
- Cypher DSL support, see neo4j-core
- Made the Lucene indexing more flexible
- Renamed size methods to count since it does simply count all the relationships (e.g. Person.all.count)
- Modularization - e.g. make it possible to create your own wrapper
- Added builder method for has_one relationships (just like ActiveRecord build_best_friend)

## [2.0.0.alpha.5 / 2012-03-27]
- Fix for HA/cluster bug [#173]
- Upgrade to neo4j-community jars 1.7.0.alpha.1
- Fix for rails 3.2 [#131]
- Fix for BatchInserter bug, [#139]
- Added rake task for upgrading [#116]
- Added scripts for upgrading database [#116]

## [2.0.0.alpha.4 / 2012-01-17]
- Fix node and rel enumerable for JRuby 1.9, Dmytrii Nagirniak
- Remove the will_paginate and move it to a separate gem Dmytrii Nagirniak, [#129][#132]
- Use type converter to determine how to handle multi-param attributes, Dmyitrii Nagirniak [#97]
- Set default storage_path in Rails to db [#96]
- Fix numeric Converter with nils and Float converter, Dmytrii Nagirniak
- Fix Neo4j::Rails::Model.find incorrect behavior with negative numbers, Dmytrii Nagirniak [#101]
- Allow to use symbols in batch inserter [#104]
- Split neo4j-jars gem into three jars, community,advanced&enterprise

 == 2.0.0.alpha.1 / 2012-01-11
- Split JARS into a separate gem (neo4j-jars) [#115]
- Changed prefix of relationships so that it allows having incoming relationships from different classes with different relationship names. Migration is needed to update an already existing database - see issue #116. [#117]
- Fix for undefined method 'add_unpersited_outgoing_rel' [#111]
- Fix for Rails models named Property [#108] (Vivek Prahlad)


 == 1.3.1 / 2011-12-14
- Make all relationships visible in Rails callback (rspecs #87, Dmytrii Nagirniak) [#211]
- Enable travis to build JRuby 1.9 (pull #87, Dmytrii Nagirniak) [#214]
- Support for composite lucene queries with OR and NOT (pull #89, Deepak N)
- Enforce the correct converter on a property type when the type is given (pull #86, Dmytrii Nagirniak)
- Development: make it easier to run RSpecs and guard (pull #85, Dmytrii Nagirniak)
- Added ability to disable observer (pull #84, Dmytrii Nagirniak)
- Fixing multiple assignment of has_one assocaition (pull #83 Deepak N)
- Accept association_id for has_one assocations (pull #82, Deepak N)
- Upgrade to 1.6.M01 Neo4j java jars [#209]
- Defer warning message 'Unknown outgoing relationship' (pull #81, Vivek Prahlad)
- Added string converter, e.g. property :name, :type => String  (pull #80, Dmytrii Nagirniak)
- Added symbol converter e.g. property :status, :type => Symbol (pull #79, Dmytrii Nagirniak) [#205]

 == 1.3.0 / 2011-12-06
- Added neo4j-upgrade script to rename lucene index files and upgrade to 1.5 [#197]
- Expose Neo4j::NodeMixin#index_types returning available indices (useful for Cypher queries) [#194]
- The to_other method is now available also in the Neo4j::Rails API [#193]
- Expose rel_type method for Neo4j::Rails::Relationship [#196]
- Support for breadth and depth first traversals [#198]
- Support for cypher query [#197]
- Fix for rule node concurrency issue (pull #78, Vivek Prahlad)
- Bugfix for the uniqueness validation for properties with quotes (pull #76, Vivek Prahlad)
- More performance tweaks (pull #75, #77, Vivek Prahlad)
- Fixing add_index for properties other than type string (pull #74, Deepak N)
- Significant performance boost for creating large numbers of models in a transaction (pull #73, Vivek Prahlad)
- Upgrade to neo4j 1.5 jars (pull #72, Vivek Prahlad)
- Fix for assigning nil values to incoming has_one relation (pull #70, Deepak N)
- Support for revert and fixes for Neo4j::Rails::Versioning (pull #71, Vivek Prahlad)

 == 1.2.6 / 2011-11-02
- Generators can now generate relationships as well [#195]
- Better will_paginate support for Neo4j::Rails::Model [#194]
- Fixing updated_at to be set only if model has changed (pull #68, Deepak N)
- Bringing back changes removed during identiy map to fix bug [#190] (Deepak N)
- Fixing updated_at to be set only if model has changed, using callbacks instead of overriding method for stamping time (Deepak N)
- Added versioning support (pull #67) (Vivek Prahlad)

 == 1.2.5 / 2011-10-21
- Faster traversals by avoiding loading Ruby wrappers (new method 'raw' on traversals) [#189]
- Support for IdentityMap [#188]
- Improved performance in event handler (Vivek Prahlad)
- Fixing issue with validates_presence_of validation (Vivek Prahlad)
- Implemented compositions support on Neo4j::Rails::Relationship (Kalyan Akella)
- Added after_initialize callback (Deepak N)
- Fixed performance issues on node deleted (Vivek Prahlad)
- Fixed a performance issue in the index_registry (Vivek Prahlad)
- Fixed uniqueness validation for :case_sensitive => false (Vivek Prahlad)
- Fixed update_attributes deleting relations when model is invalid (Deepak N)
- Fixed timestamp rails generator (Marcio Toshio)

 == 1.2.4 / 2011-10-07
- Support for traversing with Neo4j::Node#eval_paths and setting uniqueness on traversals [#187]
- Removed unnecessary node creation on database start up (class nodes attached to reference node) (Vivek Prahlad)
- Safer multitenancy - automatically reset the reference node in thread local context after each request using rack middleware
- Bugfixes for multitenancy (Deepak N and Vivek Prahlad)

 == 1.2.3 / 2011-10-01
- Multitenancy support by namespaced-indices & changeable reference node (Vivek Prahlad, pull 41)
- Added a Neo4j::Rails::Model#columns which returns all defined properties [#186]
- Fixed validation associated entities, parent model should be invalid if its nested model(s) is invalid (Vivek Prahlad)
- Fixed property validation to read value before conversion as per active model conventions (Deepak N)
- Fixed property_before_type_cast for loaded models (Deepak N)
- Better support for nested models via ActionView field_for [#185]
- BUG: fix for null pointer issue after delete_all on Neo4j::Rails::Model#has_n relationships (Vivek Prahlad)
- BUG: init_on_create was not called when creating a new relationship via the << operator [#183]

 == 1.2.2 / 2011-09-15
- Added compositions support for rails mode (Deepak N)
- Added support for nested transactions at the Rails model level (Vivek Prahlad)
- Fixing issue where save for invalid entities puts them into an inconsistent state (Vivek Prahlad)
- Fix for issue with save when validation fails (Vivek Prahlad)
- Fix for accepts_nested_attributes_for when the associated entities are created before a new node (Vivek Prahlad)
- Fix to allow has_one relationships to handle nil assignments in models (Vivek Prahlad)
- Observers support for neo4j rails model using active model (Deepak N)
- Override ActiveModel i18n_scope for neo4j (Deepak N)
- Added finders similar to active record and mongoid (Deepak N)
- Added find!, find_or_create_by and find_or_initialize_by methods, similar to active record finders (Deepak N)

 == 1.2.1 / 2011-08-29
- Fixed failing RSpecs for devise-neo4j gem - column_names method on neo4j orm adapter throws NoMethodError (thanks Deepak N)

 == 1.2.0 / 2011-08-16
- Upgrade to java library neo4j 1.4.1, see http://neo4j.rubyforge.org/guides/configuration.html

 == 1.1.4 / 2011-08-10
- Fixed dependency to will_paginate, locked to 3.0.pre4 (newly released 3.0.0 does not work yet with neo4j.rb)

  == 1.1.3 / 2011-08-09
- real recursive rule to the top class, subclasses with rules did not work (Frédéric Vanclef)
- BUG: not able to create array properties on relationships (Pere Urbon)
- BUG: lucene did not work if starting up neo4j in read only mode (like rails console when the rails is already running)

 == 1.1.2 / 2011-06-08
- Added configuration option 'enable_rules' to disable the _all relationships and custom rules [#176]
- Added a #node method on the Neo4j::Node and Neo4j::NodeMixin. Works like the #rel method but returns the node instead. [#174]
- Simplify creating relationship between two existing nodes [#175]

 == 1.1.1 / 2011-05-26
- Made neo4j compatible with rails 3.1.0.rc1 [#170]
- Fix for neo4j-devise [#171]
- BUG: Neo4j::GraphAlgo shortest path does raise exception if two nodes are not connected [#172]

 == 1.1.0 / 2011-05-13
- Support for embedding neo4j.rb by providing an already running db instance (#168)
- Neo4j::Rails::Relationships should be ActiveModel compliant (#156)
- Support for incoming relationships in Neo4j::Rails::Model (#157)
- to_json method for models no tags √ resolved (#154)
- Implement hash so that it will work with Sets (#160)
- Modified the traverser to allow iterating over paths not just over end_nodes (#161)
- Create method should take a block to initialize itself (#162)
- Upgrade to 1.3 neo4j java library (#164)
- Default `nodes' invocation for Algo path finders (#165)
- Property and index class methods modified to take arbitrary number of symbols optionally followed by options hash (#166)
- BUG: Setting property :system on Neo4j::Rails::Model should work (#163)
- BUG: update_attributes should convert values according to Type (#155)
- BUG: Neo4j::RelationshipMixin#relationship_type broken #(169)
- BUG: Relationship.load(nil) == Relationship.load(0) (#167)
- BUG: Full text search returns nil in rails model (#153)

## [1.0.0 / 2011-03-02]
- Complete rewrite of everything.
- Replaced the lucene module with using the java neo4j-lucene integration instead
- Lots of improvements of the API
- Better ActiveModel/Rails integration

## [0.4.4 / 2010-08-01]
- Fixed bug on traversing when using the RelationshipMixin (#121)
- BatchInserter and JRuby 1.6 - Fix iteration error with trying to modify in-place hash

## [0.4.3 / 2010-04-10]
- Fixed .gitignore - make sure that we do not include unnecessarily files like neo4j databases. Release 0.4.2 contained test data.
- Added synchronize around Index.new so that two thread can't modify the same index at the same time.

## [0.4.2 / 2010-04-08]
-  No index on properties for the initialize method bug (#116)
-  Tidy up Thread Synchronization in Lucene wrapper - lucene indexing performance improvement (#117)
-  Permission bug loading neo4j jar file (#118)
-  Spike: Make NodeMixin ActiveModel complient - experimental (#115)

## [0.4.1 / 2010-03-11]
- Migrations (#108)
- BatchInserter (#111)
- Neo4j::Relationship.new should take a hash of properties (#110)
- Upgrade to neo4j-1.0 (#114)
- Bigfix: has_one should replace old relationship (#106)
- Bugfix: custom accessors for NodeMixin#update (#113)
- Bugfix: Indexed properties problem on extented ruby classes critical "properties indexer" (#112)

## [0.4.0 / 2010-02-06]
- Performance improvements and Refactoring: Use and Extend Neo4j Java Classes (#97)
- Support for Index and Declaration of Properties on Relationships (#91)
- Upgrade to neo4j-1.0 rc (#100)
- All internal properties should be prefix with a '_',0.4.0 (#105)
- Generate relationship accessor methods for declared has_n and has_one relationships (#104)
- New way of creating relationship - Neo4j::Relationship.new (#103)
- Neo4j#init_node method should take one or more args (#98)
- Namespaced relationships: has_one...from using the wrong has_n...to(#92)
- Neo4j::NodeMixin and Neo4j::Node should allow a hash for initialization (#99)

## [0.3.3 / 2009-11-25]
- Support for a counter property on has_lists (#75)
- Support for Cascade delete. On has_n, had_one and has_list (#81)
- NodeMixin#all should work with inheritance - Child classes should have a relationship of their own. (#64)
- Support for other lucene analyzer then StandardAnalyzer (#87)
- NodeMixin initialize should accept block like docs (#82)
- Add incoming relationship should work as expected: n1.relationships.incoming(:foo) << n2 (#80)
- Delete node from a has_list relationship should work as expected (#79)
- Improve stacktraces (#94)
- Removed sideeffect of rspecs (#90)
- Add debug method on NodeMixin to print it self (#88)
- Removed to_a method (#73)
- Upgrade to neo4j-1.0b10 (#95)
- Upgrade to lucene 2.9.0 (#83)
- Refactoring: RSpecs (#74)
- Refactoring: aggregate each, renamed to property aggregator (#72)
- BugFix: neo4j gem cannot be built  from the source (#86)
- BugFix: Neo4j::relationship should not raise Exception if there are no relationships (#78)

## [0.3.2 / 2009-09-17]
- Added support for aggregating nodes (#65)
- Wrapped Neo4j GraphAlgo AllSimplePath (#70)
- Added traversal with traversal position (#71)
- Removed DynamicAccessors mixin, replaced by [] operator (#67)
- Impl Neo4j.all_nodes (#69)
- Upgrated Neo4j jar file to 1.0-b9
- The Neo4j#relationship method now allows a filter parameter (#66)
- Neo4j.rb now can read database not created by Neo4j.rb - does not require classname property (#63)
- REST - added an "all" value for the depth traversal query parameter (#62)
- REST - Performance improvments using the Rest Mixin (#60)

## [0.3.1 / 2009-07-25]
- Feature, extension - find path between given pair of nodes (#58)
- Fix a messy exception on GET /nodes/UnknownClassName (#57)
- Bug  - exception on GET /nodes/classname/rel if rel is a has_one relationship (#56)
- Bug: GET /nodes/classname missing out nodes with no properties (#55)
- Bug: Lucene sorting caused exception if there were no documents (#54)
- Bug: reindexer fails to connect nodes to the IndexNode (#53)

## [0.3.0 / 2009-06-25]
- Neo4j should track node changes
- RESTful support for lucene queries, sorting and paging
- RESTful support for Relationships
- RESTful support for Node and properties
- Experimental support for Master-Slave Replication via REST
- RESTful Node representation should contain hyperlinks to relationships
- Added some handy method like first and empty? on relationships
- Use new neo4j: neo-1.0-b8
- Add an event handler for create/delete nodes start/stop neo, update property/relationship
- The NodeMixin should behave like a hash, added [] and []= methods
- Support list topology - has_list and belongs_to_list Neo4j::NodeMixin Classmethods
- Should be possible to add relationships without declaring them (Neo4j#relationships.outgoing(:friends) << node)
- Neo4j extensions file structure, should be easy to create your own extensions
- Rename relation to relationship (Neo4j::Relations => Neo4j::Relationships, DynamicRelation => Relationship) [data incompatible change]
- Auto Transaction is now optional
- Setting Float properties fails under JRuby1.2.0
- Bug: Indexing relationships does not work
- Make the ReferenceNode include Neo4j::NodeMixin
- Added handy Neo4j class that simply includes the Neo4j::NodeMixin
- Neo4j::IndexNode now holds references to all nodes (Neo4j.ref_node -> Neo4j::IndexNode -> ...)


## [0.2.1 / 2009-03-15]
- Refactoring of lucene indexing of the node space (28)
- Fixed bug on Neo4j::Nodemixin#property? (#22)


## [0.2.0 / 2009-01-20]
- Impl. Neo4j::Node#traverse - enables traversal and filtering using TraversalPosition info (#17,#19)
- Impl. traversal to any depth (#15)
- Impl. traversal several relationships type at the same time (#16)
- Fixed a Lucene timezone bug (#20)
- Lots of refactoring of the neo4j.rb traversal code and RSpecs

## [0.1.0 / 2008-12-18]
- Property can now be of any type (and not only String, Fixnum, Float)
- Indexing and Query with Date and DateTime
- YARD documentation
- Properties can be removed
- A property can be set to nil (it will then be removed).

## [0.0.7 / 2008-12-10]
- Added method to_param and methods on the value object needed for Ruby on Rails
- Impl. update from a value object/hash for a node
- Impl. generation of value object classes/instances from a node.
- Refactoring the Transaction handling (reuse PlaceboTransaction instances if possible)
- Removed the need to start and stop neo. It will be done automatically when needed.


## [0.0.6 / 2008-12-03]
- Removed the configuration from the Neo4j.start method. Now exist in Neo4j::Config and Lucene::Config.
- Implemented sort_by method.
- Lazy loading of search result. Execute the query and load the nodes only if needed.
- Added support to use lucene query language, example: Person.find("name:foo AND age:42")
- All test now uses RAM based lucene indexes.

## [0.0.5 / 2008-11-17]
- Supports keeping lucene index in memory instead of on disk
- Added support for lucene full text search
- Fixed so neo4j runs on JRuby 1.1.5
- Implemented support for reindex all instances of a node class. This is needed if the lucene index is kept in memory or if the index is changed.
- Added ReferenceNode. All nodes now have a relationship from this reference node.
- Lots of refactoring
- Added the IMDB example. It shows how to create a neo database, lucene queries and node traversals.

## [0.0.4 / 2008-10-23]
- First release to rubyforge
