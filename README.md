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
  end

  person = Person.new
  person.neo_id.should be_nil
  person.save

```

See RSpecs for more examples


It uses the neo4j-core gem version 3.0

See https://github.com/andreasronge/neo4j-core


## Neo4j-wrapper API

TODO This is not updated !!!

This gem includes the old neo4j-wrapper gem.
Example of mapping a Neo4j::Node java object to your own class.

```ruby
  # will use Neo4j label 'Person'
  class Person
    include Neo4j::ActiveNode
  end

  # find all person instances
  Person.find_all
```

Using an index

```ruby
  # will use Neo4j label 'Person'
  class Person
    include Neo4j::ActiveNode
    index :name
  end

  # find all person instances with key value = name, andreas
  andreas = Person.create(:name => 'andreas')
  Person.find(:name, 'andreas')  # will include andreas
```


Example of mapping the Baaz ruby class to Neo4j labels 'Foo', 'Bar' and 'Baaz'

```ruby
  module Foo
    def self.mapped_label_name
       "Foo" # specify the label for this module
    end
  end

  module Bar
    extend Neo4j::Wrapper::LabelIndex # to make it possible to search using this module (?)
    index :stuff # (?)
  end

  class Baaz
    include Foo
    include Bar
    include Neo4j::ActiveNode
  end

  Bar.find_nodes(...) # can find Baaz object but also other objects including the Bar mixin.
```

Example of inheritance.

```ruby
  # will only use the Vehicle label
  class Vehicle
    include Neo4j::ActiveNode
  end

  # will use both Car and Vehicle labels
  class Car < Vehicle
  end
```

## Contributing

* Have you found a bug, need help or have a patch ?
* Just clone neo4j.rb and send me a pull request or email me.
* Do you need help - send me an email (andreas.ronge at gmail dot com).

## License

* Neo4j.rb - MIT, see the [LICENSE](http://github.com/andreasronge/neo4j/tree/master/LICENSE).
* Lucene -  Apache, see the [Lucene Documentation](http://lucene.apache.org/java/docs/features.html).
* Neo4j - Dual free software/commercial license, see [Lisencing Guide](http://www.neo4j.org/learn/licensing).

**Notice:** there are different license for the `neo4j-community`, `neo4j-advanced`, and `neo4j-enterprise` jar gems. Only the `neo4j-community` gem is by default required.
