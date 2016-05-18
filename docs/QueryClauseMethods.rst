QueryClauseMethods
==================

The ``Neo4j::Core::Query`` class from the `neo4j-core` gem defines a DSL which allows for easy creation of Neo4j `Cypher queries <http://neo4j.com/developer/cypher-query-language>`_.  They can be started from a session like so:

.. code-block:: ruby

  # The current session can be retrieved with `Neo4j::Session.current`
  a_session.query

Advantages of using the `Query` class include:

 * Method chaining allows you to build a part of a query and then pass it somewhere else to be built further
 * Automatic use of parameters when possible
 * Ability to pass in data directly from other sources (like Hash to match keys/values)
 * Ability to use native Ruby objects (such as translating `nil` values to `IS NULL`, regular expressions to Cypher-style regular expression matches, etc...)

Below is a series of Ruby code samples and the resulting Cypher that would be generated.  These examples are all generated directly from the `spec file <https://github.com/neo4jrb/neo4j-core/blob/master/spec/neo4j-core/unit/query_spec.rb>`_ and are thus all tested to work.

Neo4j::Core::Query
------------------

#match
~~~~~~

:Ruby:
  .. code-block:: ruby

    .match('n')

:Cypher:
  .. code-block:: cypher

    MATCH n


------------

:Ruby:
  .. code-block:: ruby

    .match(:n)

:Cypher:
  .. code-block:: cypher

    MATCH (n)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: Person)

:Cypher:
  .. code-block:: cypher

    MATCH (n:`Person`)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: 'Person')

:Cypher:
  .. code-block:: cypher

    MATCH (n:`Person`)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: ':Person')

:Cypher:
  .. code-block:: cypher

    MATCH (n:Person)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: :Person)

:Cypher:
  .. code-block:: cypher

    MATCH (n:`Person`)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: [:Person, "Animal"])

:Cypher:
  .. code-block:: cypher

    MATCH (n:`Person`:`Animal`)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: ' :Person')

:Cypher:
  .. code-block:: cypher

    MATCH (n:Person)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: nil)

:Cypher:
  .. code-block:: cypher

    MATCH (n)


------------

:Ruby:
  .. code-block:: ruby

    .match(n: 'Person {name: "Brian"}')

:Cypher:
  .. code-block:: cypher

    MATCH (n:Person {name: "Brian"})


------------

:Ruby:
  .. code-block:: ruby

    .match(n: {name: 'Brian', age: 33})

:Cypher:
  .. code-block:: cypher

    MATCH (n {name: {n_name}, age: {n_age}})

**Parameters:** ``{:n_name=>"Brian", :n_age=>33}``

------------

:Ruby:
  .. code-block:: ruby

    .match(n: {Person: {name: 'Brian', age: 33}})

:Cypher:
  .. code-block:: cypher

    MATCH (n:`Person` {name: {n_Person_name}, age: {n_Person_age}})

**Parameters:** ``{:n_Person_name=>"Brian", :n_Person_age=>33}``

------------

:Ruby:
  .. code-block:: ruby

    .match('n--o')

:Cypher:
  .. code-block:: cypher

    MATCH n--o


------------

:Ruby:
  .. code-block:: ruby

    .match('n--o', 'o--p')

:Cypher:
  .. code-block:: cypher

    MATCH n--o, o--p


------------

:Ruby:
  .. code-block:: ruby

    .match('n--o').match('o--p')

:Cypher:
  .. code-block:: cypher

    MATCH n--o, o--p


------------

#optional_match
~~~~~~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .optional_match(n: Person)

:Cypher:
  .. code-block:: cypher

    OPTIONAL MATCH (n:`Person`)


------------

:Ruby:
  .. code-block:: ruby

    .match('m--n').optional_match('n--o').match('o--p')

:Cypher:
  .. code-block:: cypher

    MATCH m--n, o--p OPTIONAL MATCH n--o


------------

#using
~~~~~~

:Ruby:
  .. code-block:: ruby

    .using('INDEX m:German(surname)')

:Cypher:
  .. code-block:: cypher

    USING INDEX m:German(surname)


------------

:Ruby:
  .. code-block:: ruby

    .using('SCAN m:German')

:Cypher:
  .. code-block:: cypher

    USING SCAN m:German


------------

:Ruby:
  .. code-block:: ruby

    .using('INDEX m:German(surname)').using('SCAN m:German')

:Cypher:
  .. code-block:: cypher

    USING INDEX m:German(surname) USING SCAN m:German


------------

#where
~~~~~~

:Ruby:
  .. code-block:: ruby

    .where()

:Cypher:
  .. code-block:: cypher

    


------------

:Ruby:
  .. code-block:: ruby

    .where({})

:Cypher:
  .. code-block:: cypher

    


------------

:Ruby:
  .. code-block:: ruby

    .where('q.age > 30')

:Cypher:
  .. code-block:: cypher

    WHERE (q.age > 30)


------------

:Ruby:
  .. code-block:: ruby

    .where('q.age' => 30)

:Cypher:
  .. code-block:: cypher

    WHERE (q.age = {q_age})

**Parameters:** ``{:q_age=>30}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.age' => [30, 32, 34])

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN {q_age})

**Parameters:** ``{:q_age=>[30, 32, 34]}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.age IN {age}', age: [30, 32, 34])

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN {age})

**Parameters:** ``{:age=>[30, 32, 34]}``

------------

:Ruby:
  .. code-block:: ruby

    .where('(q.age IN {age})', age: [30, 32, 34])

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN {age})

**Parameters:** ``{:age=>[30, 32, 34]}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.name =~ ?', '.*test.*')

:Cypher:
  .. code-block:: cypher

    WHERE (q.name =~ {question_mark_param})

**Parameters:** ``{:question_mark_param=>".*test.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where('(q.name =~ ?)', '.*test.*')

:Cypher:
  .. code-block:: cypher

    WHERE (q.name =~ {question_mark_param})

**Parameters:** ``{:question_mark_param=>".*test.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where('(LOWER(str(q.name)) =~ ?)', '.*test.*')

:Cypher:
  .. code-block:: cypher

    WHERE (LOWER(str(q.name)) =~ {question_mark_param})

**Parameters:** ``{:question_mark_param=>".*test.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.age IN ?', [30, 32, 34])

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN {question_mark_param})

**Parameters:** ``{:question_mark_param=>[30, 32, 34]}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.age IN ?', [30, 32, 34]).where('q.age != ?', 60)

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN {question_mark_param}) AND (q.age != {question_mark_param2})

**Parameters:** ``{:question_mark_param=>[30, 32, 34], :question_mark_param2=>60}``

------------

:Ruby:
  .. code-block:: ruby

    .where(q: {age: [30, 32, 34]})

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN {q_age})

**Parameters:** ``{:q_age=>[30, 32, 34]}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.age' => nil)

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IS NULL)


------------

:Ruby:
  .. code-block:: ruby

    .where(q: {age: nil})

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IS NULL)


------------

:Ruby:
  .. code-block:: ruby

    .where(q: {neo_id: 22})

:Cypher:
  .. code-block:: cypher

    WHERE (ID(q) = {ID_q})

**Parameters:** ``{:ID_q=>22}``

------------

:Ruby:
  .. code-block:: ruby

    .where(q: {age: 30, name: 'Brian'})

:Cypher:
  .. code-block:: cypher

    WHERE (q.age = {q_age} AND q.name = {q_name})

**Parameters:** ``{:q_age=>30, :q_name=>"Brian"}``

------------

:Ruby:
  .. code-block:: ruby

    .where(q: {age: 30, name: 'Brian'}).where('r.grade = 80')

:Cypher:
  .. code-block:: cypher

    WHERE (q.age = {q_age} AND q.name = {q_name}) AND (r.grade = 80)

**Parameters:** ``{:q_age=>30, :q_name=>"Brian"}``

------------

:Ruby:
  .. code-block:: ruby

    .where(q: {name: /Brian.*/i})

:Cypher:
  .. code-block:: cypher

    WHERE (q.name =~ {q_name})

**Parameters:** ``{:q_name=>"(?i)Brian.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where(name: /Brian.*/i)

:Cypher:
  .. code-block:: cypher

    WHERE (name =~ {name})

**Parameters:** ``{:name=>"(?i)Brian.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where(name: /Brian.*/i).where(name: /Smith.*/i)

:Cypher:
  .. code-block:: cypher

    WHERE (name =~ {name}) AND (name =~ {name2})

**Parameters:** ``{:name=>"(?i)Brian.*", :name2=>"(?i)Smith.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where(q: {age: (30..40)})

:Cypher:
  .. code-block:: cypher

    WHERE (q.age IN RANGE({q_age_range_min}, {q_age_range_max}))

**Parameters:** ``{:q_age_range_min=>30, :q_age_range_max=>40}``

------------

#where_not
~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .where_not()

:Cypher:
  .. code-block:: cypher

    


------------

:Ruby:
  .. code-block:: ruby

    .where_not({})

:Cypher:
  .. code-block:: cypher

    


------------

:Ruby:
  .. code-block:: ruby

    .where_not('q.age > 30')

:Cypher:
  .. code-block:: cypher

    WHERE NOT(q.age > 30)


------------

:Ruby:
  .. code-block:: ruby

    .where_not('q.age' => 30)

:Cypher:
  .. code-block:: cypher

    WHERE NOT(q.age = {q_age})

**Parameters:** ``{:q_age=>30}``

------------

:Ruby:
  .. code-block:: ruby

    .where_not('q.age IN ?', [30, 32, 34])

:Cypher:
  .. code-block:: cypher

    WHERE NOT(q.age IN {question_mark_param})

**Parameters:** ``{:question_mark_param=>[30, 32, 34]}``

------------

:Ruby:
  .. code-block:: ruby

    .where_not(q: {age: 30, name: 'Brian'})

:Cypher:
  .. code-block:: cypher

    WHERE NOT(q.age = {q_age} AND q.name = {q_name})

**Parameters:** ``{:q_age=>30, :q_name=>"Brian"}``

------------

:Ruby:
  .. code-block:: ruby

    .where_not(q: {name: /Brian.*/i})

:Cypher:
  .. code-block:: cypher

    WHERE NOT(q.name =~ {q_name})

**Parameters:** ``{:q_name=>"(?i)Brian.*"}``

------------

:Ruby:
  .. code-block:: ruby

    .where('q.age > 10').where_not('q.age > 30')

:Cypher:
  .. code-block:: cypher

    WHERE (q.age > 10) AND NOT(q.age > 30)


------------

:Ruby:
  .. code-block:: ruby

    .where_not('q.age > 30').where('q.age > 10')

:Cypher:
  .. code-block:: cypher

    WHERE NOT(q.age > 30) AND (q.age > 10)


------------

#match_nodes
~~~~~~~~~~~~

one node object
^^^^^^^^^^^^^^^

:Ruby:
  .. code-block:: ruby

    .match_nodes(var: node_object)

:Cypher:
  .. code-block:: cypher

    MATCH (var) WHERE (ID(var) = {ID_var})

**Parameters:** ``{:ID_var=>246}``

------------

:Ruby:
  .. code-block:: ruby

    .optional_match_nodes(var: node_object)

:Cypher:
  .. code-block:: cypher

    OPTIONAL MATCH (var) WHERE (ID(var) = {ID_var})

**Parameters:** ``{:ID_var=>246}``

------------

integer
^^^^^^^

:Ruby:
  .. code-block:: ruby

    .match_nodes(var: 924)

:Cypher:
  .. code-block:: cypher

    MATCH (var) WHERE (ID(var) = {ID_var})

**Parameters:** ``{:ID_var=>924}``

------------

two node objects
^^^^^^^^^^^^^^^^

:Ruby:
  .. code-block:: ruby

    .match_nodes(user: user, post: post)

:Cypher:
  .. code-block:: cypher

    MATCH (user), (post) WHERE (ID(user) = {ID_user}) AND (ID(post) = {ID_post})

**Parameters:** ``{:ID_user=>246, :ID_post=>123}``

------------

node object and integer
^^^^^^^^^^^^^^^^^^^^^^^

:Ruby:
  .. code-block:: ruby

    .match_nodes(user: user, post: 652)

:Cypher:
  .. code-block:: cypher

    MATCH (user), (post) WHERE (ID(user) = {ID_user}) AND (ID(post) = {ID_post})

**Parameters:** ``{:ID_user=>246, :ID_post=>652}``

------------

#unwind
~~~~~~~

:Ruby:
  .. code-block:: ruby

    .unwind('val AS x')

:Cypher:
  .. code-block:: cypher

    UNWIND val AS x


------------

:Ruby:
  .. code-block:: ruby

    .unwind(x: :val)

:Cypher:
  .. code-block:: cypher

    UNWIND val AS x


------------

:Ruby:
  .. code-block:: ruby

    .unwind(x: 'val')

:Cypher:
  .. code-block:: cypher

    UNWIND val AS x


------------

:Ruby:
  .. code-block:: ruby

    .unwind(x: [1,3,5])

:Cypher:
  .. code-block:: cypher

    UNWIND [1, 3, 5] AS x


------------

:Ruby:
  .. code-block:: ruby

    .unwind(x: [1,3,5]).unwind('val as y')

:Cypher:
  .. code-block:: cypher

    UNWIND [1, 3, 5] AS x UNWIND val as y


------------

#return
~~~~~~~

:Ruby:
  .. code-block:: ruby

    .return('q')

:Cypher:
  .. code-block:: cypher

    RETURN q


------------

:Ruby:
  .. code-block:: ruby

    .return(:q)

:Cypher:
  .. code-block:: cypher

    RETURN q


------------

:Ruby:
  .. code-block:: ruby

    .return('q.name, q.age')

:Cypher:
  .. code-block:: cypher

    RETURN q.name, q.age


------------

:Ruby:
  .. code-block:: ruby

    .return(q: [:name, :age], r: :grade)

:Cypher:
  .. code-block:: cypher

    RETURN q.name, q.age, r.grade


------------

:Ruby:
  .. code-block:: ruby

    .return(q: :neo_id)

:Cypher:
  .. code-block:: cypher

    RETURN ID(q)


------------

:Ruby:
  .. code-block:: ruby

    .return(q: [:neo_id, :prop])

:Cypher:
  .. code-block:: cypher

    RETURN ID(q), q.prop


------------

#order
~~~~~~

:Ruby:
  .. code-block:: ruby

    .order('q.name')

:Cypher:
  .. code-block:: cypher

    ORDER BY q.name


------------

:Ruby:
  .. code-block:: ruby

    .order_by('q.name')

:Cypher:
  .. code-block:: cypher

    ORDER BY q.name


------------

:Ruby:
  .. code-block:: ruby

    .order('q.age', 'q.name DESC')

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age, q.name DESC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: :age)

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age


------------

:Ruby:
  .. code-block:: ruby

    .order(q: :neo_id)

:Cypher:
  .. code-block:: cypher

    ORDER BY ID(q)


------------

:Ruby:
  .. code-block:: ruby

    .order(q: [:age, {name: :desc}])

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age, q.name DESC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: [:age, {neo_id: :desc}])

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age, ID(q) DESC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: [:age, {name: :desc, grade: :asc}])

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age, q.name DESC, q.grade ASC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: [:age, {name: :desc, neo_id: :asc}])

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age, q.name DESC, ID(q) ASC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: {age: :asc, name: :desc})

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age ASC, q.name DESC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: {age: :asc, neo_id: :desc})

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age ASC, ID(q) DESC


------------

:Ruby:
  .. code-block:: ruby

    .order(q: [:age, 'name desc'])

:Cypher:
  .. code-block:: cypher

    ORDER BY q.age, q.name desc


------------

:Ruby:
  .. code-block:: ruby

    .order(q: [:neo_id, 'name desc'])

:Cypher:
  .. code-block:: cypher

    ORDER BY ID(q), q.name desc


------------

#limit
~~~~~~

:Ruby:
  .. code-block:: ruby

    .limit(3)

:Cypher:
  .. code-block:: cypher

    LIMIT {limit_3}

**Parameters:** ``{:limit_3=>3}``

------------

:Ruby:
  .. code-block:: ruby

    .limit('3')

:Cypher:
  .. code-block:: cypher

    LIMIT {limit_3}

**Parameters:** ``{:limit_3=>3}``

------------

:Ruby:
  .. code-block:: ruby

    .limit(3).limit(5)

:Cypher:
  .. code-block:: cypher

    LIMIT {limit_5}

**Parameters:** ``{:limit_3=>3, :limit_5=>5}``

------------

:Ruby:
  .. code-block:: ruby

    .limit(nil)

:Cypher:
  .. code-block:: cypher

    


------------

#skip
~~~~~

:Ruby:
  .. code-block:: ruby

    .skip(5)

:Cypher:
  .. code-block:: cypher

    SKIP {skip_5}

**Parameters:** ``{:skip_5=>5}``

------------

:Ruby:
  .. code-block:: ruby

    .skip('5')

:Cypher:
  .. code-block:: cypher

    SKIP {skip_5}

**Parameters:** ``{:skip_5=>5}``

------------

:Ruby:
  .. code-block:: ruby

    .skip(5).skip(10)

:Cypher:
  .. code-block:: cypher

    SKIP {skip_10}

**Parameters:** ``{:skip_5=>5, :skip_10=>10}``

------------

:Ruby:
  .. code-block:: ruby

    .offset(6)

:Cypher:
  .. code-block:: cypher

    SKIP {skip_6}

**Parameters:** ``{:skip_6=>6}``

------------

#with
~~~~~

:Ruby:
  .. code-block:: ruby

    .with('n.age AS age')

:Cypher:
  .. code-block:: cypher

    WITH n.age AS age


------------

:Ruby:
  .. code-block:: ruby

    .with('n.age AS age', 'count(n) as c')

:Cypher:
  .. code-block:: cypher

    WITH n.age AS age, count(n) as c


------------

:Ruby:
  .. code-block:: ruby

    .with(['n.age AS age', 'count(n) as c'])

:Cypher:
  .. code-block:: cypher

    WITH n.age AS age, count(n) as c


------------

:Ruby:
  .. code-block:: ruby

    .with(age: 'n.age')

:Cypher:
  .. code-block:: cypher

    WITH n.age AS age


------------

#create
~~~~~~~

:Ruby:
  .. code-block:: ruby

    .create('(:Person)')

:Cypher:
  .. code-block:: cypher

    CREATE (:Person)


------------

:Ruby:
  .. code-block:: ruby

    .create(:Person)

:Cypher:
  .. code-block:: cypher

    CREATE (:Person)


------------

:Ruby:
  .. code-block:: ruby

    .create(age: 41, height: 70)

:Cypher:
  .. code-block:: cypher

    CREATE ( {age: {age}, height: {height}})

**Parameters:** ``{:age=>41, :height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create(Person: {age: 41, height: 70})

:Cypher:
  .. code-block:: cypher

    CREATE (:`Person` {age: {Person_age}, height: {Person_height}})

**Parameters:** ``{:Person_age=>41, :Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create(q: {Person: {age: 41, height: 70}})

:Cypher:
  .. code-block:: cypher

    CREATE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>41, :q_Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create(q: {Person: {age: nil, height: 70}})

:Cypher:
  .. code-block:: cypher

    CREATE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>nil, :q_Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create(q: {:'Child:Person' => {age: 41, height: 70}})

:Cypher:
  .. code-block:: cypher

    CREATE (q:`Child:Person` {age: {q_Child_Person_age}, height: {q_Child_Person_height}})

**Parameters:** ``{:q_Child_Person_age=>41, :q_Child_Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create(:'Child:Person' => {age: 41, height: 70})

:Cypher:
  .. code-block:: cypher

    CREATE (:`Child:Person` {age: {Child_Person_age}, height: {Child_Person_height}})

**Parameters:** ``{:Child_Person_age=>41, :Child_Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create(q: {[:Child, :Person] => {age: 41, height: 70}})

:Cypher:
  .. code-block:: cypher

    CREATE (q:`Child`:`Person` {age: {q_Child_Person_age}, height: {q_Child_Person_height}})

**Parameters:** ``{:q_Child_Person_age=>41, :q_Child_Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create([:Child, :Person] => {age: 41, height: 70})

:Cypher:
  .. code-block:: cypher

    CREATE (:`Child`:`Person` {age: {Child_Person_age}, height: {Child_Person_height}})

**Parameters:** ``{:Child_Person_age=>41, :Child_Person_height=>70}``

------------

#create_unique
~~~~~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .create_unique('(:Person)')

:Cypher:
  .. code-block:: cypher

    CREATE UNIQUE (:Person)


------------

:Ruby:
  .. code-block:: ruby

    .create_unique(:Person)

:Cypher:
  .. code-block:: cypher

    CREATE UNIQUE (:Person)


------------

:Ruby:
  .. code-block:: ruby

    .create_unique(age: 41, height: 70)

:Cypher:
  .. code-block:: cypher

    CREATE UNIQUE ( {age: {age}, height: {height}})

**Parameters:** ``{:age=>41, :height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create_unique(Person: {age: 41, height: 70})

:Cypher:
  .. code-block:: cypher

    CREATE UNIQUE (:`Person` {age: {Person_age}, height: {Person_height}})

**Parameters:** ``{:Person_age=>41, :Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .create_unique(q: {Person: {age: 41, height: 70}})

:Cypher:
  .. code-block:: cypher

    CREATE UNIQUE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>41, :q_Person_height=>70}``

------------

#merge
~~~~~~

:Ruby:
  .. code-block:: ruby

    .merge('(:Person)')

:Cypher:
  .. code-block:: cypher

    MERGE (:Person)


------------

:Ruby:
  .. code-block:: ruby

    .merge(:Person)

:Cypher:
  .. code-block:: cypher

    MERGE (:Person)


------------

:Ruby:
  .. code-block:: ruby

    .merge(:Person).merge(:Thing)

:Cypher:
  .. code-block:: cypher

    MERGE (:Person) MERGE (:Thing)


------------

:Ruby:
  .. code-block:: ruby

    .merge(age: 41, height: 70)

:Cypher:
  .. code-block:: cypher

    MERGE ( {age: {age}, height: {height}})

**Parameters:** ``{:age=>41, :height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .merge(Person: {age: 41, height: 70})

:Cypher:
  .. code-block:: cypher

    MERGE (:`Person` {age: {Person_age}, height: {Person_height}})

**Parameters:** ``{:Person_age=>41, :Person_height=>70}``

------------

:Ruby:
  .. code-block:: ruby

    .merge(q: {Person: {age: 41, height: 70}})

:Cypher:
  .. code-block:: cypher

    MERGE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>41, :q_Person_height=>70}``

------------

#delete
~~~~~~~

:Ruby:
  .. code-block:: ruby

    .delete('n')

:Cypher:
  .. code-block:: cypher

    DELETE n


------------

:Ruby:
  .. code-block:: ruby

    .delete(:n)

:Cypher:
  .. code-block:: cypher

    DELETE n


------------

:Ruby:
  .. code-block:: ruby

    .delete('n', :o)

:Cypher:
  .. code-block:: cypher

    DELETE n, o


------------

:Ruby:
  .. code-block:: ruby

    .delete(['n', :o])

:Cypher:
  .. code-block:: cypher

    DELETE n, o


------------

:Ruby:
  .. code-block:: ruby

    .detach_delete('n')

:Cypher:
  .. code-block:: cypher

    DETACH DELETE n


------------

:Ruby:
  .. code-block:: ruby

    .detach_delete(:n)

:Cypher:
  .. code-block:: cypher

    DETACH DELETE n


------------

:Ruby:
  .. code-block:: ruby

    .detach_delete('n', :o)

:Cypher:
  .. code-block:: cypher

    DETACH DELETE n, o


------------

:Ruby:
  .. code-block:: ruby

    .detach_delete(['n', :o])

:Cypher:
  .. code-block:: cypher

    DETACH DELETE n, o


------------

#set_props
~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .set_props('n = {name: "Brian"}')

:Cypher:
  .. code-block:: cypher

    SET n = {name: "Brian"}


------------

:Ruby:
  .. code-block:: ruby

    .set_props(n: {name: 'Brian', age: 30})

:Cypher:
  .. code-block:: cypher

    SET n = {n_set_props}

**Parameters:** ``{:n_set_props=>{:name=>"Brian", :age=>30}}``

------------

#set
~~~~

:Ruby:
  .. code-block:: ruby

    .set('n = {name: "Brian"}')

:Cypher:
  .. code-block:: cypher

    SET n = {name: "Brian"}


------------

:Ruby:
  .. code-block:: ruby

    .set(n: {name: 'Brian', age: 30})

:Cypher:
  .. code-block:: cypher

    SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

:Ruby:
  .. code-block:: ruby

    .set(n: {name: 'Brian', age: 30}, o: {age: 29})

:Cypher:
  .. code-block:: cypher

    SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.`age` = {setter_o_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30, :setter_o_age=>29}``

------------

:Ruby:
  .. code-block:: ruby

    .set(n: {name: 'Brian', age: 30}).set_props('o.age = 29')

:Cypher:
  .. code-block:: cypher

    SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.age = 29

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

:Ruby:
  .. code-block:: ruby

    .set(n: :Label)

:Cypher:
  .. code-block:: cypher

    SET n:`Label`


------------

:Ruby:
  .. code-block:: ruby

    .set(n: [:Label, 'Foo'])

:Cypher:
  .. code-block:: cypher

    SET n:`Label`, n:`Foo`


------------

:Ruby:
  .. code-block:: ruby

    .set(n: nil)

:Cypher:
  .. code-block:: cypher

    


------------

#on_create_set
~~~~~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .on_create_set('n = {name: "Brian"}')

:Cypher:
  .. code-block:: cypher

    ON CREATE SET n = {name: "Brian"}


------------

:Ruby:
  .. code-block:: ruby

    .on_create_set(n: {})

:Cypher:
  .. code-block:: cypher

    


------------

:Ruby:
  .. code-block:: ruby

    .on_create_set(n: {name: 'Brian', age: 30})

:Cypher:
  .. code-block:: cypher

    ON CREATE SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

:Ruby:
  .. code-block:: ruby

    .on_create_set(n: {name: 'Brian', age: 30}, o: {age: 29})

:Cypher:
  .. code-block:: cypher

    ON CREATE SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.`age` = {setter_o_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30, :setter_o_age=>29}``

------------

:Ruby:
  .. code-block:: ruby

    .on_create_set(n: {name: 'Brian', age: 30}).on_create_set('o.age = 29')

:Cypher:
  .. code-block:: cypher

    ON CREATE SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.age = 29

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

#on_match_set
~~~~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .on_match_set('n = {name: "Brian"}')

:Cypher:
  .. code-block:: cypher

    ON MATCH SET n = {name: "Brian"}


------------

:Ruby:
  .. code-block:: ruby

    .on_match_set(n: {})

:Cypher:
  .. code-block:: cypher

    


------------

:Ruby:
  .. code-block:: ruby

    .on_match_set(n: {name: 'Brian', age: 30})

:Cypher:
  .. code-block:: cypher

    ON MATCH SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

:Ruby:
  .. code-block:: ruby

    .on_match_set(n: {name: 'Brian', age: 30}, o: {age: 29})

:Cypher:
  .. code-block:: cypher

    ON MATCH SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.`age` = {setter_o_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30, :setter_o_age=>29}``

------------

:Ruby:
  .. code-block:: ruby

    .on_match_set(n: {name: 'Brian', age: 30}).on_match_set('o.age = 29')

:Cypher:
  .. code-block:: cypher

    ON MATCH SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.age = 29

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

#remove
~~~~~~~

:Ruby:
  .. code-block:: ruby

    .remove('n.prop')

:Cypher:
  .. code-block:: cypher

    REMOVE n.prop


------------

:Ruby:
  .. code-block:: ruby

    .remove('n:American')

:Cypher:
  .. code-block:: cypher

    REMOVE n:American


------------

:Ruby:
  .. code-block:: ruby

    .remove(n: 'prop')

:Cypher:
  .. code-block:: cypher

    REMOVE n.prop


------------

:Ruby:
  .. code-block:: ruby

    .remove(n: :American)

:Cypher:
  .. code-block:: cypher

    REMOVE n:`American`


------------

:Ruby:
  .. code-block:: ruby

    .remove(n: [:American, "prop"])

:Cypher:
  .. code-block:: cypher

    REMOVE n:`American`, n.prop


------------

:Ruby:
  .. code-block:: ruby

    .remove(n: :American, o: 'prop')

:Cypher:
  .. code-block:: cypher

    REMOVE n:`American`, o.prop


------------

:Ruby:
  .. code-block:: ruby

    .remove(n: ':prop')

:Cypher:
  .. code-block:: cypher

    REMOVE n:`prop`


------------

#start
~~~~~~

:Ruby:
  .. code-block:: ruby

    .start('r=node:nodes(name = "Brian")')

:Cypher:
  .. code-block:: cypher

    START r=node:nodes(name = "Brian")


------------

:Ruby:
  .. code-block:: ruby

    .start(r: 'node:nodes(name = "Brian")')

:Cypher:
  .. code-block:: cypher

    START r = node:nodes(name = "Brian")


------------

clause combinations
~~~~~~~~~~~~~~~~~~~

:Ruby:
  .. code-block:: ruby

    .match(q: Person).where('q.age > 30')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) WHERE (q.age > 30)


------------

:Ruby:
  .. code-block:: ruby

    .where('q.age > 30').match(q: Person)

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) WHERE (q.age > 30)


------------

:Ruby:
  .. code-block:: ruby

    .where('q.age > 30').start('n').match(q: Person)

:Cypher:
  .. code-block:: cypher

    START n MATCH (q:`Person`) WHERE (q.age > 30)


------------

:Ruby:
  .. code-block:: ruby

    .match(q: {age: 30}).set_props(q: {age: 31})

:Cypher:
  .. code-block:: cypher

    MATCH (q {age: {q_age}}) SET q = {q_set_props}

**Parameters:** ``{:q_age=>30, :q_set_props=>{:age=>31}}``

------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).with('count(q) AS count')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) WITH count(q) AS count


------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).with('count(q) AS count').where('count > 2')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) WITH count(q) AS count WHERE (count > 2)


------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).with(count: 'count(q)').where('count > 2').with(new_count: 'count + 5')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) WITH count(q) AS count WHERE (count > 2) WITH count + 5 AS new_count


------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).match('r:Car').break.match('(p: Person)-->q')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`), r:Car MATCH (p: Person)-->q


------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).break.match('r:Car').break.match('(p: Person)-->q')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) MATCH r:Car MATCH (p: Person)-->q


------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).match('r:Car').break.break.match('(p: Person)-->q')

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`), r:Car MATCH (p: Person)-->q


------------

:Ruby:
  .. code-block:: ruby

    .with(:a).order(a: {name: :desc}).where(a: {name: 'Foo'})

:Cypher:
  .. code-block:: cypher

    WITH a ORDER BY a.name DESC WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo"}``

------------

:Ruby:
  .. code-block:: ruby

    .with(:a).limit(2).where(a: {name: 'Foo'})

:Cypher:
  .. code-block:: cypher

    WITH a LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

:Ruby:
  .. code-block:: ruby

    .with(:a).order(a: {name: :desc}).limit(2).where(a: {name: 'Foo'})

:Cypher:
  .. code-block:: cypher

    WITH a ORDER BY a.name DESC LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

:Ruby:
  .. code-block:: ruby

    .order(a: {name: :desc}).with(:a).where(a: {name: 'Foo'})

:Cypher:
  .. code-block:: cypher

    WITH a ORDER BY a.name DESC WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo"}``

------------

:Ruby:
  .. code-block:: ruby

    .limit(2).with(:a).where(a: {name: 'Foo'})

:Cypher:
  .. code-block:: cypher

    WITH a LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

:Ruby:
  .. code-block:: ruby

    .order(a: {name: :desc}).limit(2).with(:a).where(a: {name: 'Foo'})

:Cypher:
  .. code-block:: cypher

    WITH a ORDER BY a.name DESC LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

:Ruby:
  .. code-block:: ruby

    .with('1 AS a').where(a: 1).limit(2)

:Cypher:
  .. code-block:: cypher

    WITH 1 AS a WHERE (a = {a}) LIMIT {limit_2}

**Parameters:** ``{:a=>1, :limit_2=>2}``

------------

:Ruby:
  .. code-block:: ruby

    .match(q: Person).where('q.age = {age}').params(age: 15)

:Cypher:
  .. code-block:: cypher

    MATCH (q:`Person`) WHERE (q.age = {age})

**Parameters:** ``{:age=>15}``

------------

