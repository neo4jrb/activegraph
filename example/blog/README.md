## README

This is a very basic Rails application working together with both the server and embedded API of the
Neo4j Graph Database.


### Neo4j Server

Install gem dependencies using either MRI or JRuby

```
bundle install
```

Start and install development database:

```
rake neo4j:install[community-2.1.3]
rake neo4j:start
```

Start rails:

```
rails s
```

open a browser: http://localhost:3000, or http://localhost:7474 for the admin UI

### Neo4j Embedded

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


## Testing

Install a Neo4j test server

```
rake neo4j:install[community-2.1.3,test]
```

Configure it using a different server port e.g. 7475

```
rake neo4j:config[test,7475]
rake neo4j:start[test]
```

Edit the test configuration `config/environments/test`

```
config.neo4j.session_type = :server_db
config.neo4j.session_path = 'http://localhost:7475'
```
