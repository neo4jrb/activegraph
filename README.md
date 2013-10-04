# Welcome to Neo4j.rb [![Build Status](https://secure.travis-ci.org/andreasronge/neo4j.png?branch=master)](http://travis-ci.org/andreasronge/neo4j) [![Dependency Status](https://gemnasium.com/andreasronge/neo4j.png)](https://gemnasium.com/andreasronge/neo4j)

Neo4j.rb is a graph database for [JRuby](jruby.org).

You can think of Neo4j as a high-performance graph engine with all the features of a mature and robust database. The programmer works with an object-oriented, flexible network structure rather than with strict and static tables — yet enjoys all the benefits of a fully transactional, enterprise-strength database. This JRuby gem uses the mature [Neo4j Java library](http://www.neo4j.org).

It has been tested with Neo4j version 1.8.2 and 1.9.M03 ([see here](https://github.com/andreasronge/neo4j-core/blob/master/neo4j-core.gemspec)) and JRuby 1.7.4 ([see Travis](https://travis-ci.org/andreasronge/neo4j)).

Notice, you do not need to install the Neo4j server since this gem comes included with the database. However, if you still want to use the Neo4j server (e.g. the admin UI) you can connect the embedded database with the Neo4j server using a [Neo4j HA Cluster](https://github.com/andreasronge/neo4j/wiki/Neo4j%3A%3Aha-cluster).

### Future

See https://github.com/andreasronge/neo4j-core/tree/3.0
This means that in the future, neo4j.rb will support both neo4j server (MRI and JRuby) and neo4j embedded (only JRuby).
Also, check the neoid (https://github.com/elado/neoid) which probably will use the neo4j-core v3.0 gem.

### Documentation

* [Github Wiki](https://github.com/andreasronge/neo4j/wiki)
* [Blog](http://blog.jayway.com/2012/05/07/neo4j-rb-2-0-an-overview/)
* [YARD](http://rdoc.info/github/andreasronge/neo4j/master/frames)
* [Specs](https://github.com/andreasronge/neo4j/tree/master/spec) - There are 2023 RSpecs (478/neo4j-core, 425/neo4j-wrapper and 1120/this gem - 2012 April)
* [Docs from Neo Technology](http://docs.neo4j.org/)

### Example applications

* [Neo4j.rb with HA Cluster Screencast](http://youtu.be/PblrbrT5JNY)
* [The Kvitter Rails 3.2x App](https://github.com/andreasronge/kvitter) (kvitter = tweets in Swedish)
* [Gritter (Rails 3.2)](https://github.com/saterus/gritter) Another Twitter clone, but with User Auth, Posts, and Follower Recommendations.
* [Simple Rails 3.0 App](https://github.com/andreasronge/neo4j-rails-example)

### Why Neo4j.rb or any Graph Database?

Major benefits of Neo4j.rb:

* Domain Modeling - use the language of a graph (nodes/relationship/properties) to express your domain!
  * Schema Less and Efficient storage of Semi Structured Information
  * No [O/R mismatch](http://en.wikipedia.org/wiki/Object-relational_impedance_mismatch) - very natural to map a graph to an Object Oriented language like Ruby.
* [Performance](http://www.oscon.com/oscon2009/public/schedule/detail/8364)
* Embedded Database - no database tier, easier to install, test, deploy and configure. It is run in the same process as your application.
* Express Queries as Traversals
  * Fast deep traversal instead of slow SQL queries that span many table joins.
  * Very natural to express graph related problem with traversals (recommendation engine, find shortest parth etc..)
* Seamless integration with Ruby on Rails.
* ACID Transaction with rollbacks support.

## Project Layout

The Ruby libraries for Neo4j are divided into 4 separate gems.

* Layer 3: [`neo4j`](https://github.com/andreasronge/neo4j) provides all the niceties you'd expect from a Rails ORM. *(You are here..)* An implementation of the Rails Active Model and a subset of the Active Record API, see `Neo4j::Rails::Model` and `Neo4j::Rails::Relationship`.
* Layer 2: [`neo4j-wrapper`](https://github.com/andreasronge/neo4j-wrapper) provides Ruby wrappers for objects and query results. A binding API to Ruby objects, see `Neo4j::NodeMixin` and `Neo4j::RelationshipMixin`.
* Layer 1: [`neo4j-core`](https://github.com/andreasronge/neo4j-core) is a JRuby compatibility layer over the standard Java Neo4j API. For interacting with the basic building blocks of the graph database (node, properties and relationship), see `Neo4j::Node` and `Neo4j::Relationship`.
* Additionally, [`neo4j-cypher`](https://github.com/andreasronge/neo4j-cypher) provides a DSL for the [Cypher Query Language](http://docs.neo4j.org/chunked/snapshot/cypher-query-lang.html). The DSL lets you create Cypher queries in an easy to understand way instead of hand-crafting strings.

*Notice that you can always access the lower layers if you want to do something more advanced. You can even access the Java API directly.*

The `neo4j` gem depends on the `neo4j-wrapper`, `neo4j-core`, and `neo4j-cypher` gem. You can use `neo4j-wrapper` directly if you do not need the Rails functionality.

The documentation for all projects is combined in the [`neo4j` Wiki](https://github.com/andreasronge/neo4j/wiki).

Additionally, the [`neo4j-community`](https://github.com/dnagir/neo4j-community), [`neo4j-advanced`](https://github.com/dnagir/neo4j-advanced), [`neo4j-enterprise`](https://github.com/dnagir/neo4j-enterprise) gems provide the necessary jars to embed the Neo4j server. Due to licensing concerns, only `neo4j-community` is required by default.

## [The Neo4j gem](https://github.com/andreasronge/neo4j)

Major components of the Neo4j gem include:

* [Neo4j::Rails::Model](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/Model)
* [Neo4j::Rails::Relationship](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/Relationship)
* [Neo4j::Rails::Observer](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/Observer)
* [Neo4j::Rails::HaConsole::Railitie](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/HaConsole/Railtie)
* [Neo4j::Rails::Versioning](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/Versioning)
* [Neo4j::Rails::Compositions::ClassMethods](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/Compositions/ClassMethods)
* [Neo4j::Rails::AcceptId](http://rdoc.info/github/andreasronge/neo4j/Neo4j/Rails/AcceptId)

### Generating a Rails Application

Example of creating an Neo4j Application from scratch:

**Make sure you are using JRuby!**

```bash
gem install rails -v '< 4'
rails new myapp -m http://andreasronge.github.com/neo4j/rails.rb -O
cd myapp
bundle
rails generate scaffold User name:string email:string
rails s
open a webbrowser: http://localhost:3000/users
```

The -O flag above means that it will skip active record. For more information, read the [Scaffolds & Generators Wiki](https://github.com/andreasronge/neo4j/wiki/Neo4j%3A%3ARails-Scaffolds-%26-Generators).

### Examples

Example of using Neo4j with Rails 3 (ActiveModel)

```ruby
class User < Neo4j::Rails::Model
  attr_accessor :password
  attr_accessible :email, :password, :password_confirmation, :pending_account

  after_save   :encrypt_password

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  # add an exact lucene index on the email property
  property :email, index: :exact

  has_one(:avatar).to(Avatar)

  validates :email, presence: true, format: { :with => email_regex }
  validates :email, uniqueness: true, unless: :pending_account?
  accepts_nested_attributes_for :avatar, allow_destroy: true

end

u = User.new(name: 'kalle', age: 42, email: "bla@foo.com")
u.save
```

## [The neo4j-wrapper gem](https://github.com/andreasronge/neo4j-wrapper)

The `neo4j-wrapper` gem provides both the [Neo4j::NodeMixin](http://rdoc.info/github/andreasronge/neo4j-wrapper/Neo4j/NodeMixin) and [Neo4j::RelationshipMixin](http://rdoc.info/github/andreasronge/neo4j-wrapper/Neo4j/RelationshipMixin). These can be mixed into normal Ruby classes to provide a persistence mechanism for Neo4j.

### Example

Example of mapping a Ruby class to a Node and delaring Properties and Relationships and Lucene index.

```ruby
class Person
  include Neo4j::NodeMixin
  property :name, index: :exact
  property :city

  has_n :friends
  has_one :address
end

# NOTE: we *must* perform write operations in a transaction!
Neo4j::Transaction.run do
  andreas = Person.new (:name => 'andreas')
  andreas.friends << Person.new (:name => 'peter')
  andreas.friends.each {|person| puts "name #{person.name}" }
  Person.find("name: andreas").first.name # => 'andreas'
end
```

## [The neo4j-core gem](https://github.com/andreasronge/neo4j-core)

The `neo4j-core` gem provides a thin layer around the Java API.

* [Neo4j::Node](http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Node) The Java Neo4j Node
* [Neo4j::Relationship](http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Relationship) The Java Relationship
* [Neo4j](http://rdoc.info/github/andreasronge/neo4j-core/Neo4j) The Database
* [Neo4j::Algo](http://rdoc.info/github/andreasronge/neo4j-core/Neo4j/Algo) Included algorithms, like shortest_path

### Example

Example of creating a Neo4j::Node

```ruby
require 'neo4j-core'

Neo4j::Transaction.run do
  node = Neo4j::Node.new(:name => 'andreas')
  node.outgoing(:friends) << Neo4j::Node.new(:name => 'peter')
  node.outgoing(:friends).each {|node| puts "name #{node[:name]}"}
end
```

## Rails/Neo4j.rb in a Cluster ?

Yes, check [Neo4j.rb Ha Cluster](https://github.com/andreasronge/neo4j/wiki/Neo4j%3A%3Aha-cluster) or [Screencast](http://youtu.be/PblrbrT5JNY). Notice, you don't need to install the Neo4j Server, but it could be a useful tool to visualize the graph.

## Project information

* [GitHub](http://github.com/andreasronge/neo4j/tree/master)
* [Issue Tracking](https://github.com/andreasronge/neo4j/issues)
* [Twitter](http://twitter.com/ronge)
* [Mailing list, neo4jrb@googlegroups.com](http://groups.google.com/group/neo4jrb)
* [\#neo4j on IRC](http://webchat.freenode.net?channels=neo4j)

## Configuration

[Development configuration](http://neo4j.rubyforge.org/guides/index.html#development-and-testing-configuration)

You can configure Neo4j through the [Neo4j::Config](http://neo4j.rubyforge.org/Neo4j/Config.html) object.

```ruby
Neo4j::Config[:storage_path] = "/var/neo4j"
```

[Configuring Neo4j from Rails](http://neo4j.rubyforge.org/guides/configuration.html#config-neo4j-from-rails)

When using Neo4j.rb from Rails you can use the normal Rails `config/application.rb` to set Neo4j configuration.

```ruby
config.neo4j.storage_path = "#{config.root}/db/neo4j"
```

## Deployment

Neo4j.rb uses [Neo4j](http://neo4j.org) in embedded mode. This is great, but means that deploying to Heroku or other restricted environments is out. Luckily, you can use Neo4j.rb running on any number of unrestricted environments.

* [Neo4j.org](http://neo4j.org) has a lot of [instructional videos on dev ops](http://www.neo4j.org/develop/ops) and [deploying your app to production](http://www.neo4j.org/learn/production).
* [Chris Fitzpatrick](https://github.com/cfitz) has [written up an excellent guide](http://janitor.se/blog/2013/07/04/easier-neo4j-dot-rb-deployments-with-chef-plus-capistrano-plus-torquebox/) for using [Chef](https://github.com/opscode/chef/) to deploy your new Neo4j.rb app to a VPS like [Digital Ocean](https://www.digitalocean.com/), [Linode](https://www.linode.com/), or [EC2](https://aws.amazon.com/ec2/).
* The [Neo4j Manual](http://docs.neo4j.org/chunked/snapshot/operations.html) has details of the finer points of operations and deployement.
* [Graph Databases](http://graphdatabases.com/) by [Ian Robinson](https://twitter.com/iansrobinson), [Jim Webber](https://twitter.com/jimwebber), and [Emil Eifrem](https://twitter.com/emileifrem) has a large section on planning, deploying, and scaling your Neo4j database. 


## Contributing

* Have you found a bug, need help or have a patch ?
* Just clone neo4j.rb and send me a pull request or email me.
* Do you need help - send me an email (andreas.ronge at gmail dot com).

## License

* Neo4j.rb - MIT, see the [LICENSE](http://github.com/andreasronge/neo4j/tree/master/LICENSE).
* Lucene -  Apache, see the [Lucene Documentation](http://lucene.apache.org/java/docs/features.html).
* Neo4j - Dual free software/commercial license, see [Lisencing Guide](http://www.neo4j.org/learn/licensing).

**Notice:** there are different license for the `neo4j-community`, `neo4j-advanced`, and `neo4j-enterprise` jar gems. Only the `neo4j-community` gem is by default required.
