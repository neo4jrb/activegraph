# WARNING : RAKE AUTO-GENERATED FILE. DO NOT MANUALLY EDIT!
# LAST UPDATED : Thu Mar 12 21:20:07 +0100 2009
#
# RUN : 'rake gem:update_gemspec'

Gem::Specification.new do |s|
 s.date = "Thu Mar 12 00:00:00 +0100 2009"
 s.version = "0.2.0"
 s.authors = ["Andreas Ronge"]
 s.require_paths = ["lib"]
 s.name = "neo4j"
 s.required_rubygems_version = ">= 0"
 s.has_rdoc = "true"
 s.specification_version = "2"
 s.loaded = "false"
 s.files = ["LICENSE",
 "CHANGELOG",
 "README.rdoc",
 "Rakefile",
 "neo4j.gemspec",
 "lib/neo4j.rb",
 "lib/lucene",
 "lib/lucene/index_info.rb",
 "lib/lucene/jars",
 "lib/lucene/jars/lucene-core-2.4.0.jar",
 "lib/lucene/field_info.rb",
 "lib/lucene/config.rb",
 "lib/lucene/jars.rb",
 "lib/lucene/index_searcher.rb",
 "lib/lucene/index.rb",
 "lib/lucene/hits.rb",
 "lib/lucene/query_dsl.rb",
 "lib/lucene/document.rb",
 "lib/lucene/transaction.rb",
 "lib/lucene.rb",
 "lib/neo4j",
 "lib/neo4j/reference_node.rb",
 "lib/neo4j/mixins",
 "lib/neo4j/mixins/transactional.rb",
 "lib/neo4j/mixins/node.rb",
 "lib/neo4j/mixins/relation.rb",
 "lib/neo4j/mixins/dynamic_accessor.rb",
 "lib/neo4j/version.rb",
 "lib/neo4j/jars",
 "lib/neo4j/jars/jta-spec1_0_1.jar",
 "lib/neo4j/jars/neo-1.0-b7.jar",
 "lib/neo4j/jars/shell-1.0-b7.jar",
 "lib/neo4j/events.rb",
 "lib/neo4j/config.rb",
 "lib/neo4j/jars.rb",
 "lib/neo4j/indexer.rb",
 "lib/neo4j/search_result.rb",
 "lib/neo4j/neo.rb",
 "lib/neo4j/transaction.rb",
 "lib/neo4j/relations",
 "lib/neo4j/relations/relations.rb",
 "lib/neo4j/relations/relation_info.rb",
 "lib/neo4j/relations/has_n.rb",
 "lib/neo4j/relations/node_traverser.rb",
 "lib/neo4j/relations/dynamic_relation.rb",
 "lib/neo4j/relations/traversal_position.rb",
 "lib/neo4j/relations/relation_traverser.rb",
 "test/lucene",
 "test/lucene/sort_spec.rb",
 "test/lucene/transaction_spec.rb",
 "test/lucene/index_info_spec.rb",
 "test/lucene/spec_helper.rb",
 "test/lucene/query_dsl_spec.rb",
 "test/lucene/document_spec.rb",
 "test/lucene/field_info_spec.rb",
 "test/lucene/index_spec.rb",
 "test/neo4j",
 "test/neo4j/relation_traverser_spec.rb",
 "test/neo4j/neo_spec.rb",
 "test/neo4j/transaction_spec.rb",
 "test/neo4j/spec_helper.rb",
 "test/neo4j/node_traverser_spec.rb",
 "test/neo4j/has_one_spec.rb",
 "test/neo4j/indexer_spec.rb",
 "test/neo4j/node_lucene_spec.rb",
 "test/neo4j/order_spec.rb",
 "test/neo4j/index_spec.rb",
 "test/neo4j/value_object_spec.rb",
 "test/neo4j/property_spec.rb",
 "test/neo4j/ref_node_spec.rb",
 "test/neo4j/person_spec.rb",
 "test/neo4j/has_n_spec.rb",
 "test/neo4j/node_mixin_spec.rb",
 "examples/imdb",
 "examples/imdb/install.sh",
 "examples/imdb/model.rb",
 "examples/imdb/find_actors.rb",
 "examples/imdb/create_neo_db.rb",
 "examples/imdb/db",
 "examples/imdb/db/neo",
 "examples/imdb/db/neo/neostore.propertystore.db.strings",
 "examples/imdb/db/neo/neostore.propertystore.db.index.id",
 "examples/imdb/db/neo/neostore.propertystore.db.index.keys.id",
 "examples/imdb/db/neo/neostore.relationshiptypestore.db",
 "examples/imdb/db/neo/neostore.propertystore.db.index.keys",
 "examples/imdb/db/neo/neostore.id",
 "examples/imdb/db/neo/neostore.relationshiptypestore.db.id",
 "examples/imdb/db/neo/neostore.relationshipstore.db",
 "examples/imdb/db/neo/neostore.propertystore.db.strings.id",
 "examples/imdb/db/neo/neostore.relationshipstore.db.id",
 "examples/imdb/db/neo/neostore.propertystore.db.arrays.id",
 "examples/imdb/db/neo/neostore.nodestore.db.id",
 "examples/imdb/db/neo/tm_tx_log.1",
 "examples/imdb/db/neo/neostore.propertystore.db.arrays",
 "examples/imdb/db/neo/neostore.relationshiptypestore.db.names.id",
 "examples/imdb/db/neo/neostore.relationshiptypestore.db.names",
 "examples/imdb/db/neo/neostore.propertystore.db.index",
 "examples/imdb/db/neo/neostore.propertystore.db",
 "examples/imdb/db/neo/neostore.propertystore.db.id",
 "examples/imdb/db/neo/active_tx_log",
 "examples/imdb/db/neo/neostore.nodestore.db",
 "examples/imdb/db/neo/neostore",
 "examples/imdb/data",
 "examples/imdb/data/test-movies.list",
 "examples/imdb/data/test-actors.list"]
 s.email = "andreas.ronge@gmail.com"
 s.required_ruby_version = ">= 1.8.4"
 s.rubygems_version = "1.3.1"
 s.homepage = "http://github.com/andreasronge/neo4j/tree"
 s.extra_rdoc_files = ["README.rdoc"]
 s.platform = "ruby"
 s.rubyforge_project = "neo4j"
 s.rdoc_options = ["--quiet", "--title", "Neo4j.rb", "--opname", "index.html", "--line-numbers", "--main", "README.rdoc", "--inline-source"]
 s.summary = "A graph database for JRuby"
 s.description = "A graph database for JRuby"
 s.bindir = "bin"
end