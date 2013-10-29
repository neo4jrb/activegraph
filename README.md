# Welcome to Neo4j.rb [![Build Status](https://secure.travis-ci.org/andreasronge/neo4j.png?branch=master)](http://travis-ci.org/andreasronge/neo4j) [![Dependency Status](https://gemnasium.com/andreasronge/neo4j.png)](https://gemnasium.com/andreasronge/neo4j)
/Users/andreasronge/projects/neo4j-core/lib/neo4j-wrapper/delegates.rb
Neo4j.rb is a graph database for Ruby (and JRuby)

## Version 3.0

### Usage from Ruby

Example, Open a session to the neo4j server database:

```ruby
  Neo4j::Session.open(:server_db, "http://localhost:7474")
```

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
  end

  person = Person.new
  person.neo_id.should be_nil
  person.save

```



## Neo4j-core and Neo4j-wrapper

See https://github.com/andreasronge/neo4j-core/tree/3.0


## Contributing

* Have you found a bug, need help or have a patch ?
* Just clone neo4j.rb and send me a pull request or email me.
* Do you need help - send me an email (andreas.ronge at gmail dot com).

## License

* Neo4j.rb - MIT, see the [LICENSE](http://github.com/andreasronge/neo4j/tree/master/LICENSE).
* Lucene -  Apache, see the [Lucene Documentation](http://lucene.apache.org/java/docs/features.html).
* Neo4j - Dual free software/commercial license, see [Lisencing Guide](http://www.neo4j.org/learn/licensing).

**Notice:** there are different license for the `neo4j-community`, `neo4j-advanced`, and `neo4j-enterprise` jar gems. Only the `neo4j-community` gem is by default required.
