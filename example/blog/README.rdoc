== README

This is a very basic Rails application working together with both the server and embedded API of the
Neo4j Graph Database.


=== Neo4j Server

Install gem dependencies using either MRI or JRuby

```
bundle install
```

Start and install database:

```
rake neo4j:install[community-2.0.0]
rake neo4j:start
```

Start rails:

```
rails s
```

open a browser: http://localhost:3000

=== Neo4j Embedded

Add the following to lines in the `config/application.rb` file:

```
config.neo4j.session_type = :embedded_db
config.neo4j.session_path = File.expand_path('neo4j-db', Rails.root)
```

Make sure you are running on JRuby (`rvm jruby`)
Install dependencies and start

```
bundle install
rails s
```

open a browser: http://localhost:3000

===

Notice, many features of the 2.x version are not implemented yet, such as relationship
(but it is impl. in the neo4j-core layer), or more advanced index and search options.