# Change Log
All notable changes to this project will be documented in this file.
This file should follow the standards specified on [http://keepachangelog.com/]
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

- Add support for undeclared properties on specific models (see #1294 / thanks @klobuczek)
- Add `update_node_property` and `update_node_properties` methods, aliased as `update_column` and `update_columns`, to persist changes without triggering validations, callbacks, timestamps, etc,...

## [8.0.0.alpha.12] 2016-09-29

### Fixed

- Allow multiple arguments to scopes (see #1297 / thanks @klobuczek)
- Fixed validations with unpersisted nodes (see #1293 / thanks @klobuczek & @ProGM)
- Fixed various association bugs (see #1293 / thanks @klobuczek & @ProGM)
- Fix `as` losing the current query chain scope (see #1298 and #1278 / thanks @ProGM & @ernestoe)

## [8.0.0.alpha.11] 2016-09-27

### Fixed
- Don't fire database when accessing to unpersisted model associations (thanks @klobuczek & @ProGM see #1273)
- `size` and `length` methods not taking account of `@deferred_objects` (see #1293)
- `update` was not rolling-back association changes when validations fail
- Broken Rails `neo4j:migrate_v8` generator

# Changed
- `count` method in associations, now always fire the database like AR does
- Neo4j now passes all association validations specs, taken from AR (thanks @klobuczek)

## [8.0.0.alpha.10] 2016-09-16

### Fixed
- Remove blank objects from association results to be compatible with `ActiveRecord` (see #1276 / thanks klobuczek)
- Allow https scheme in the NEO4J_URL (see #1287 / thanks jacob-ewald)

## [8.0.0.alpha.9] 2016-09-14

### Fixed

- String / symbol issue for session types in railtie
- Put in fix for allowing models to reload for wrapping nodes / relationshps

## [8.0.0.alpha.8] 2016-09-14

### Fixed

- Issues with railtie

## [8.0.0.alpha.7] 2016-09-13

### Changed

- Multiple sessions in Rails config no longer supported

## [8.0.0.alpha.6] 2016-09-12

### Fixed

- Instead of using `session_type`, `session_url`, `session_path`, and `session_options` in config `session.type`, `session.url`, `session.path`, and `session.options` should now be used.
- Issue where `session_url` (now `session.url`) was not working
- Broken sessions when threading

## [8.0.0.alpha.5] 2016-09-08

### Fixed

- Various issues with not be able to run migrations when migration were pending (see 22b7e6aaadd46c11d421b4dac8d3fb15f663a4c4)

## [8.0.0.alpha.4] 2016-09-08

### Added

- A `Neo4j::Migrations.maintain_test_schema!` method, to keep the test database up to date with schema changes. (see #1277)
- A `Neo4j::Migrations.check_for_pending_migrations!` method, that fails when there are pending migration. In Rails, it's executed automatically on startup. (see #1277)
- Support for [`ForbiddenAttributesProtection` API](http://edgeapi.rubyonrails.org/classes/ActionController/StrongParameters.html) from ActiveRecord. (thanks ProGM, see #1245)

### Changed

- `ActiveNode#destroy` and `ActiveRel#destroy` now return the object in question rather than `true` to be compatible with `ActiveRecord` (see #1254)

### Fixed

- Bugs with using `neo_id` as `ActiveNode` `id_property` (thanks klobuczek / see #1274)

## [8.0.0.alpha.3]

### Skipped

## [8.0.0.alpha.2] 2016-08-05

### Changed

- Improve migration output format / show execution time in migrations

### Fixed

- Caching of model index and constraint checks
- Error when running schema migrations.  Migrations now give a warning and instructions if a migration fails and cannot be recovered
- Error when running rake tasks to generate "force" creations of indexes / constraints and there is no migration directory
- `WARNING` is no longer displayed for constraints defined from `id_property` (either one which is implict or explict)

## [8.0.0.alpha.1] 2016-08-02

### Changed

- Improved `QueryProxy` and `AssociationProxy` `#inspect` method to show a result preview (thanks ProGM / see #1228 #1232)
- Renamed the old migration task to `neo4j:legacy_migrate`
- Renamed the ENV variable to silence migrations output from `silenced` to `MIGRATIONS_SILENCED`
- Changed the behavior with transactions when a validation fails. This is a potentially breaking change, since now calling `save` would not fail the current transaction, as expected. (thanks ProGM / see #1156)
- Invalid options to the `property` method now raise an exception (see #1169)
- Label #indexes/#constraints return array without needing to access [:property_keys]
- `server_db` server type is no longer supported.  Use `http` instead to connect to Neo4j via the HTTP JSON API

### Added

- Allow to pass a Proc for a default property value (thanks @knapo / see #1250)
- Adding a new ActiveRecord-like migration framework (thanks ProGM / see #1197)
- Adding a set of rake tasks to manage migrations (thanks ProGM / see #1197)
- Implemented autoloading for new and legacy migration modules (there's no need to `require` them anymore)
- Adding explicit identity method for use in Query strings (thanks brucek / see #1159)
- New adaptor-based API has been created for connecting to Neo4j (See the [upgrade guide](TODO!!!!)).  Changes include:
- The old APIs are deprecated and will be removed later.
- In the new API, there is no such thing as a "current" session.  Users of `neo4j-core` must create and maintain references themselves to their sessions
- New `Neo4j::Core::Node` and `Neo4j::Core::Relationshp` classes have been created to provide consistent results between adaptors.  `Neo4j::Core::Path` has also been added
- New API is centered around Cypher.  No special methods are defined to, for example, load/create/etc... nodes/relationships
- There is now a new API for making multiple queries in the same HTTP request
- It is now possible to subscribe separately to events for querying in different adaptors and for HTTP requests (see [the docs](TODO!!!!))
- Schema queries (changes to indexes/constraints) happen in a separate thread for performance and reduce the complexity of the code
- New session API does not include replacement for on_next_session_available
- Adding a migration helper to mass relabel migrations (thanks @JustinAiken / see #1166 #1239)
- Added support for `find_or_initialize_by` and `first_or_initialize` methods from ActiveRecord (thanks ProGM / see #1164)
- Support for using Neo4j-provided IDs (`neo_id`) instead of UUID or another Ruby-provided ID. (Huge thanks to @klobuczek, see #1174)

### Fixed

- Made some memory optimizations (thanks ProGM / see #1221)

## [7.2.3] - 09-28-2016

### Fixed

- `as` resetting scope of the current query chain (see #1298)

## [7.2.2] - 09-22-2016

### Fixed

- `where` clause with question mark parameter and array values only using the first element (see #1247 #1290)

## [7.2.1] - 09-19-2016

### Fixed

- During ActiveRel create, node and rel property values formatted like Cypher props (`{val}`) were interpreted as props, causing errors.

## [7.2.0] - 08-23-2016

### Added

- Backporting #1245 to 7.x versions. It implements the [`ForbiddenAttributesProtection` API](http://edgeapi.rubyonrails.org/classes/ActionController/StrongParameters.html) from ActiveRecord.

## [7.1.4] - 09-20-2016

### Fixed

- `where` clause with question mark parameter and array values only using the first element (see #1247 #1290)

## [7.1.3] - 08-18-2016

### Changed

- Default value for `enum` is `nil` instead of the first value.  This is a **BREAKING** change but is being released as a patch because the original behavior was considered a bug.  See [this pull request](https://github.com/neo4jrb/neo4j/pull/1270) (thanks to ProGM and andyweiss1982)

## [7.1.2] - 08-01-2016

### Fixed

- Fixed issue where the label wrapping cache would get stuck

## [7.1.1] - 07-22-2016

### Fixed

- `AssociationProxy` changed so that `pluck` can be used in rails/acivesupport 5 (thanks ProGM / see #1243)

## [7.1.0] - 07-14-2016

### Changed

- Gemspec dependency requirements were modified where ActiveModel, ActiveSupport, and Railties are concerned. The gem now requires >= 4.0, < 5.1.
- `ActiveModel::Serializers::Xml` is only included if supported if available.

## [7.0.16] - 09-20-2016

### Fixed

- `where` clause with question mark parameter and array values only using the first element (see #1247 #1290)

## [7.0.15] - 08-18-2016

### Changed

- Default value for `enum` is `nil` instead of the first value.  This is a **BREAKING** change but is being released as a patch because the original behavior was considered a bug.  See [this pull request](https://github.com/neo4jrb/neo4j/pull/1270) (thanks to ProGM and andyweiss1982)

## [7.0.14] - 07-10-2016

### Fixed

- Bug in setting `NEO4J_TYPE` (thanks bloomdido / see #1235)

## [7.0.12] - 06-27-2016

### Fixed

- Bug where models weren't being loaded correctly by label (thanks bloomdido / see #1220)

## [7.0.11] - 06-09-2016

### Fixed

- Fix dipendence from JSON when using outside of rails (thanks ProGM)

## [7.0.10] - 06-07-2016

### Fixed

- Calling `.create` on associations shouldn't involve extra queries (thanks for the report from rahulmeena13 / see #1216)

## [7.0.9] - 05-30-2016

### Fixed

- Fix to parens in Cypher query for `with_associations` for Neo4j 3.0 (thanks ProGM / see #1211)

## [7.0.8] - 05-27-2016

### Fixed

- Fix to `find_in_batches` (thanks to ProGM / see #1208)

## [7.0.7] - 05-26-2016

### Fixed

- Allow models to use their superclass' scopes (forward-ported from 6.1.11 / thanks to veetow for the heads-up / see #1205)

## [7.0.6] - 05-11-2016

### Added

- Explination about why you can't have an index and a constraint at the same time

## [7.0.5] - 05-06-2016

### Fixed

- Added parens to delete_all query to support new required syntax in Neo4j 3.0

## [7.0.4] - 05-06-2016

### Fixed

- A bug/inconsistency between ActiveNode's class method `create` and instance `save` led to faulty validation of associations in some cases.

## [7.0.3] - 04-28-2016

### Fixed

- Added parens to queries to support new required syntax in Neo4j 3.0

## [7.0.2] - 04-10-2016

### Fixed

- Multiparameter Attributes for properties of type `Time` were failing due to a hack that should have been removed with `ActiveAttr`'s removal
- Rel creation factory was not using backticks around rel type during create action.

## [7.0.1] - 03-22-2016

### Fixed

- Conversion of string values from form inputs (thanks to jbhannah / see #1163)

## [7.0.0] - 03-18-2016

No changes from `rc.7`

## [7.0.0.rc.7] - 03-16-2016

### Changed

- `with_associations` now generates separate `OPTIONAL MATCH` clauses, separated by `WITH` clauses and is preceeded by a `WITH` clause.

## [7.0.0.rc.6] - 03-16-2016

### Fixed

- Question mark methods (`node.foo?`) broke when ActiveAttr was removed

## [7.0.0.rc.5] - 03-14-2016

### Fixed

- Fixed issue where backticks weren't being added to where clauses for `with_associations`

## [7.0.0.rc.4] - 03-11-2016

### Fixed

- Catching errors for 404s in Rails (thanks ProGm, see #1153)

## [7.0.0.rc.3] - 03-08-2016

### Fixed

- Allow for array values when querying for enums (i.e. `where(enum_field: [:value1, :value2])`) (see #1150)

## [7.0.0.rc.2] - 03-08-2016

### Fixed

- Issue where creating relationships via `has_one` association created two relationships (forward ported from 6.0.7 / 6.1.9)

## [7.0.0.rc.1] - 03-08-2016

### Changed

- All explicit dependencies on `ActiveAttr` code that was not removed outright can now be found in the `Neo4j::Shared` namespace.
- All type conversion uses Neo4j.rb-owned converters in the `Neo4j::Shared::TypeConverters` namespace. This is of particular importance where `Boolean` is concerned. Where explicitly using `ActiveAttr::Typecasting::Boolean`, use `Neo4j::Shared::Boolean`.
- `Neo4j::Shared::TypeConverters.converters` was replaced with `Neo4j::Shared::TypeConverters::CONVERTERS`.
- Error classes refactor: All errors now inherits from `Neo4j::Error`. All specific `InvalidParameterError` were replaced with a more generic `Neo4j::InvalidParameterError`.
- When calling `Node.find(...)` with missing ids, `Neo4j::RecordNotFound` now returns a better error message and some informations about the query.

#### Internal

- Ran transpec and fixed error warning (thanks brucek / #1132)

### Added

- A number of modules and unit tests were moved directly from the ActiveAttr gem, which is no longer being maintained.
- `ActiveNode` models now respond to `update_all` (thanks ProGM / #1113)
- Association chains now respond to `update_all` and `update_all_rels` (thanks ProGM / #1113)
- Rails will now rescue all `Neo4j::RecordNotFound` errors with a 404 status code by default
- A clone of [ActiveRecord::Enum](http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html) API. See docs for details. (thanks ProGM / #1129)
- Added #branch method to `QueryProxy` to allow for easy branching of matches in association chains (thanks ProGM / #1147 / #1143)
- The `.match` method on ActiveNode model class has changed to allow a second argument which takes `on_create`, `on_match`, and `set` keys.  These allow you to define attribute values for the Cypher `MERGE` in the different cases (thanks leviwilson / see #1123)

### Removed

- All external [ActiveAttr](https://github.com/cgriego/active_attr) dependencies.
- All `call` class methods from Type Converters. Use `to_ruby` instead.
- `Neo4j::ActiveNode::Labels::InvalidQueryError`, since it's unused.

## [6.1.12] - 05-27-2016

### Fixed

- Fix to `find_in_batches` (thanks to ProGM / see #1208)

## [6.1.11] - 05-25-2016

### Fixed

- Allow models to use their superclass' scopes (thanks to veetow for the heads-up / see #1205)

## [6.1.10] - 03-14-2016

### Fixed

- Fixed issue where backticks weren't being added to where clauses for `with_associations`

## [6.1.9] - 2016-03-08

### Fixed

- Issue where creating relationships via `has_one` association created two relationships (forward ported from 6.0.7)

## [6.1.8] - 2016-03-02

### Fixed

- The `@attributes` hash of the first node of each class returned from the database would have have the wrong id property key. This did not appear to cause any problems accessing the value and would be normal for subsequent saves of the affected node as well as all other nodes.

## [6.1.7] - 2016-02-16

### Fixed

- Bug related to creating subclassed nodes alongside rels in ActiveRel. (#1135. Thanks, brucek!)

## [6.1.6] - 2016-02-03

### Added

- `wait_for_connection` configuration variable allows you to tell the gem to wait for up to 60 seconds for Neo4j to be available.  This is useful in environments such as Docker Compose

## [6.1.5] - 2016-01-28

### Fixed

- Calls to `.find`/`.find_by_id`/`.find_by_ids` now respect scopes and associations

## [6.1.4] - 2016-01-26

### Fixed

- Model generators now respect module namespaces (thanks to michaeldelorenzo in #1119)

## [6.1.3] - 2016-01-20

### Fixed

- Issue where `ActiveRel.create` would not work with `RelatedNode` (`rel.from_node`) instances (Thanks, djvs #1107)

## [6.1.2] - 2016-01-19

### Fixed

- Issue where `inspect` failed outside of Rails (Thanks to louspringer, #1111)

## [6.1.1] - 2016-01-01

### Fixed

- Fixed version requirement for `neo4j-core` in gemspec

## [6.1.0] - 2016-01-01

### Changed

- When a `model_class` is specified on an association which is not an ActiveNode model, an error is raised
- The `model_class` option on associations can no longer be a `Class` constant (should be a String, Symbol, nil, false, or an Array of Symbols/Strings)
- The `rel_class` option on associations can no longer be a `Class` constant (should be a String, Symbol, or nil)
- The `from_class` and `to_class` arguments can no longer be a `Class` constant (should be a String, Symbol, :any, or false)
- ActiveNode and ActiveRel models can now be marshaled (thanks to jhoffner for the suggestion in #1093)

### Fixed

- Inheritance of properties in ActiveRel is fixed (see #1080)

### Added

- `config/neo4j.yml` now renders with an ERB step (thanks to mrstif via #1060)
- `#increment`, `#increment!` and `#concurrent_increment!` methods added to instances of ActiveNode and ActiveRel (thanks to ProGM in #1074)

## [6.0.9] - 05-27-2016

### Fixed

- Fix to `find_in_batches` (thanks to ProGM / see #1208)

## [6.0.8] - 03-14-2016

### Fixed

- Fixed issue where backticks weren't being added to where clauses for `with_associations`

## [6.0.7] - 03-08-2016

### Fixed

- Issue where creating relationships via `has_one` association created two relationships

## [6.0.6] - 01-20-2016

### Fixed

- Issue where `inspect` failed outside of Rails (Thanks to louspringer, #1111)

## [6.0.5] - 12-29-2015

### Fixed

- If a property and a scope have the same name, a "Stack level too deep" error occurs.  Fixed by removing the instance method which scopes define.  Could break something, but I very much doubt anybody is using this, and if they are it's likely a bug (#1088)

## [6.0.4] - 12-23-2015

### Fixed

- When a `model_class` is specified on an association which is not an ActiveNode model, an error is raised

## [6.0.3] - 12-18-2015

### Fixed

- Fixed issue where find_or_create was prioritizing property`s default value rather than what was being passed in (Thanks to brucek via #1071)

## [6.0.2] - 12-16-2015

### Fixed

- Fixed issue where association setting can't be set on initialize via #new (#1065)

## [6.0.1] - 11-27-2015

### Fixed

- `#with_associations` should use multiple `OPTIONAL MATCH` clauses instead of one so that matches are independent (behavior changed in Neo4j 2.3.0) (forward ported from 5.2.15)

## [6.0.0] - 11-24-2015

### Fixed

- Refactor unpersisted association logic to store objects directly on the object rather than the association proxy since different association proxies may be created at different times (see #1043)

## [6.0.0.rc.4] - 11-19-2015

### Fixed

- Following a '#with' with a '#count' no longer causes issues with variables specified twice

## [6.0.0.rc.3] - 11-18-2015

### Fixed

- Removed extra `MATCH` which occurs from `proxy_as` calls

## [6.0.0.rc.2] - 11-17-2015

### Changed

- `QueryProxy#<<` and `#create`, when `rel_class` option is set, will use `RelClass.create!` instead of `create` to alert the user of failed rel creations.

## [6.0.0.rc.1] - 11-13-2015

This release contains no changes since the last alpha. Below are all modifications introduced in alpha releases.

### Changed

- `_classname` property has been completely removed, officially dropping support for Neo4j < 2.1.5.
- `ActiveRel#creates_unique` and the `:unique` Association option take arguments to control how the query is built. See https://github.com/neo4jrb/neo4j/pull/1038.
- `#<<` and `#create` methods on associations now create with the `rel_class` when available so that validations/callbacks/defaults are all used as expected
- Allow calling of `#method=` methods via model `new` method `Hash` argument
- Remove uniqueness validation for `id_property` because we already have Neo4j constraints
- Improved eager loading when no with_associations is specified (see #905)
- Change size and length so that they match expected Ruby / ActiveRecord behavior (see http://stackoverflow.com/questions/6083219/activerecord-size-vs-count and #875)
- Refactoring around indexing and constraints in `Neo4j::ActiveNode`. The public interfaces are unchanged.
- `Neo4j::Shared::DeclaredPropertyManager` was renamed `Neo4j::Shared::DeclaredProperties`. All methods referencing the old name were updated to reflect this.
- Methods that were using `Neo4j::Session#on_session_available` were updated to reflect the upstream change to `on_next_session_available`.
- `rel_where` will now use ActiveRel classes for type conversion, when possible.
- Converters will look for a `converted?` method to determine whether an object is of the appropriate type for the database. This allows converters to be responsible for multiple types, if required.
- Removed the ability to set both an exact index and unique constraint on the same property in a model. Unique constraints also provide exact indexes.
- Deprecated all methods in ActiveRel's Query module except for those that allow finding by id.
- Return `true` on successful `#save!` calls (Thanks to jmdeldin)

### Added

- Optional three-argument signature for `ActiveRel#create` and `#create!`, just like `initialize`.
- Alternate `ActiveRel` init syntax: `RelClass.new(from_node, to_node, args)`. This is optional, so giving a single hash with props with or without nodes is still possible.
- `ActiveRel` `create` actions can now handle unpersisted nodes.
- `rel_order` method for association chaining
- Support `config/neo4j.yaml`
- Look for ENV variables for Neo4j URL / path for Rails apps
- New classes for schema operations, predictably called `Neo4j::Schema::Operation` and subclasses `UniqueConstraintOperation` and `ExactIndexOperation`. These provide methods to aid in the additional, removal, and presence checking of indexes and constraints.
- A few methods were added to `Neo4j::Shared::DeclaredProperties` to make it easier to work with. In particular, `[key]` acts as a shortcut for `DeclaredProperties#registered_properties`.
- Type Converters were added for String, Integer, Fixnum, BigDecimal, and Boolean to provide type conversion for these objects in QueryProxy.
- Support for Array arguments to ActiveRel's `from_class` and `to_class`.

### Fixed

- Regression RE: properties being overwritten with their defaults on save in alpha.10.
- Long properties in `ActiveNode`/`ActiveRel` `#inspect` are truncated
- Property defaults are set initially when an instance of a model is loaded, then checked again before save to ensure `valid?` works.
- `QueryProxy` was not converting Boolean properties correctly
- Certain actions that were intended as once-in-the-app's-lifetime events, notably schema operations, will only occur immediately upon the first session's establishment.
- Context now set for Model.all QueryProxy so that logs can reflect that it wasn't just a raw Cypher query

### Removed

- Railtie was removing username/password and putting them into the session options.  This has been unneccessary in `neo4j-core` for a while now

## [6.0.0.alpha.12] - 11-5-2015

### Changed
- `_classname` property has been completely removed, officially dropping support for Neo4j < 2.1.5.
- `ActiveRel#creates_unique` and the `:unique` Association option take arguments to control how the query is built. See https://github.com/neo4jrb/neo4j/pull/1038.

### Added
- Optional three-argument signature for `ActiveRel#create` and `#create!`, just like `initialize`.

## [6.0.0.alpha.11] - 11-3-2015

### Fixed
- Regression RE: properties being overwritten with their defaults on save in alpha.10.

### Changed
- `#<<` and `#create` methods on associations now create with the `rel_class` when available so that validations/callbacks/defaults are all used as expected
- Allow calling of `#method=` methods via model `new` method `Hash` argument

### Added
- Alternate `ActiveRel` init syntax: `RelClass.new(from_node, to_node, args)`. This is optional, so giving a single hash with props with or without nodes is still possible.

## [6.0.0.alpha.10] - 11-2-2015

### Fixed
- Long properties in `ActiveNode`/`ActiveRel` `#inspect` are truncated
- Property defaults are set initially when an instance of a model is loaded, then checked again before save to ensure `valid?` works.

### Added
- `ActiveRel` `create` actions can now handle unpersisted nodes.

## [6.0.0.alpha.9] - 10-27-2015

### Fixed
- `uninitialized constant Neo4j::Core::CypherSession` error

## [6.0.0.alpha.8] - 10-19-2015

### Added

- `rel_order` method for association chaining

## [6.0.0.alpha.7] - 10-19-2015

### Changed

- Remove uniqueness validation for `id_property` because we already have Neo4j constraints

### Added

- Support `config/neo4j.yaml`

## [6.0.0.alpha.6] - 10-18-2015

### Changed

- Improved eager loading when no with_associations is specified (see #905)

## [6.0.0.alpha.5] - 10-18-2015

### Changed

- Change size and length so that they match expected Ruby / ActiveRecord behavior (see http://stackoverflow.com/questions/6083219/activerecord-size-vs-count and #875)

## [6.0.0.alpha.4] - 10-17-2015

### Fixed

- `QueryProxy` was not converting Boolean properties correctly

## [6.0.0.alpha.3] - 10-14-2015

### Removed

- Railtie was removing username/password and putting them into the session options.  This has been unneccessary in `neo4j-core` for a while now

## [6.0.0.alpha.2] - 10-14-2015

### Added

- Look for ENV variables for Neo4j URL / path for Rails apps

## [6.0.0.alpha.1] - 10-12-2015

### Changed

- Refactoring around indexing and constraints in `Neo4j::ActiveNode`. The public interfaces are unchanged.
- `Neo4j::Shared::DeclaredPropertyManager` was renamed `Neo4j::Shared::DeclaredProperties`. All methods referencing the old name were updated to reflect this.
- Methods that were using `Neo4j::Session#on_session_available` were updated to reflect the upstream change to `on_next_session_available`.
- `rel_where` will now use ActiveRel classes for type conversion, when possible.
- Converters will look for a `converted?` method to determine whether an object is of the appropriate type for the database. This allows converters to be responsible for multiple types, if required.
- Removed the ability to set both an exact index and unique constraint on the same property in a model. Unique constraints also provide exact indexes.
- Deprecated all methods in ActiveRel's Query module except for those that allow finding by id.
- Return `true` on successful `#save!` calls (Thanks to jmdeldin)

### Added

- New classes for schema operations, predictably called `Neo4j::Schema::Operation` and subclasses `UniqueConstraintOperation` and `ExactIndexOperation`. These provide methods to aid in the additional, removal, and presence checking of indexes and constraints.
- A few methods were added to `Neo4j::Shared::DeclaredProperties` to make it easier to work with. In particular, `[key]` acts as a shortcut for `DeclaredProperties#registered_properties`.
- Type Converters were added for String, Integer, Fixnum, BigDecimal, and Boolean to provide type conversion for these objects in QueryProxy.
- Support for Array arguments to ActiveRel's `from_class` and `to_class`.

### Fixed

- Certain actions that were intended as once-in-the-app's-lifetime events, notably schema operations, will only occur immediately upon the first session's establishment.
- Context now set for Model.all QueryProxy so that logs can reflect that it wasn't just a raw Cypher query

## [5.2.15] - 11-27-2015

### Fixed

- `#with_associations` should use multiple `OPTIONAL MATCH` clauses instead of one so that matches are independent (behavior changed in Neo4j 2.3.0)

## [5.2.13] - 10-26-2015

### Fixed
- Fixed `#after_initialize` and `#after_find` callbacks.
- The `#touch` method should to raise errors when unsuccessful and avoid `#attributes` for performance.

## [5.2.12] - 10-25-2015

### Fixed
- Fix the `#touch` method for `ActiveNode` and `ActiveRel`

## [5.2.11] - 10-18-2015

### Fixed
- Unable to give additional options as first argument to chained QueryProxy method

## [5.2.10] - 10-14-2015

### Fixed
- `has_one` does not define `_id` methods if they are already defined.  Also use `method_defined?` instead of `respond_to?` since it is at the class level

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
