# Welcome to Neo4j.rb [![Build Status](https://secure.travis-ci.org/andreasronge/neo4j.png?branch=master)](http://travis-ci.org/andreasronge/neo4j) [![Dependency Status](https://gemnasium.com/andreasronge/neo4j.png)](https://gemnasium.com/andreasronge/neo4j)
/Users/andreasronge/projects/neo4j-core/lib/neo4j-wrapper/delegates.rb
Neo4j.rb is a graph database for Ruby (and JRuby)

## Version 3.0

### Usage from Ruby

Installation of Neo4j Server and start server:

```
rake neo4j:install[community-2.0.0,RC1]
rake neo4j:start
```

(The Rake task has been copied from architect4r)


Example, Open a session to the neo4j server database (in IRB for example)

```ruby
  Neo4j::Session.open(:server_db, "http://localhost:7474")
```

After you have created a session you can now use the database, see below.

### Usage from JRuby

On JRuby you can access the database in two different ways: using the embedded db or the server db.

Example, Open a session to the neo4j embedded database (running in the same JVM)

```ruby
  session = Neo4j::Session.open(:embedded_db, '/folder/db')
  session.start
```

## Examples


```ruby

  class Person
    include Neo4j::ActiveModel
    property :name
  end

  person = Person.new
  person.name = 'kalle'
  person.save

```

The neo4j gem uses the neo4j-core gem, see https://github.com/andreasronge/neo4j-core

### Rails Example

See Rails 4 example: https://github.com/andreasronge/neo4j/tree/3.0/example/blog


## Contributing

* Have you found a bug, need help or have a patch ?
* Just clone neo4j.rb and send me a pull request or email me.
* Do you need help - send me an email (andreas.ronge at gmail dot com).

## License

* Neo4j.rb - MIT, see the [LICENSE](http://github.com/andreasronge/neo4j/tree/master/LICENSE).
* Lucene -  Apache, see the [Lucene Documentation](http://lucene.apache.org/java/docs/features.html).
* Neo4j - Dual free software/commercial license, see [Lisencing Guide](http://www.neo4j.org/learn/licensing).

**Notice:** there are different license for the `neo4j-community`, `neo4j-advanced`, and `neo4j-enterprise` jar gems. Only the `neo4j-community` gem is by default required.
