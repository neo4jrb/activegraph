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

.. code-block:: ruby

  .match('n')

.. code-block:: cypher

  MATCH n


------------

.. code-block:: ruby

  .match(:n)

.. code-block:: cypher

  MATCH n


------------

.. code-block:: ruby

  .match(n: Person)

.. code-block:: cypher

  MATCH (n:`Person`)


------------

.. code-block:: ruby

  .match(n: 'Person')

.. code-block:: cypher

  MATCH (n:`Person`)


------------

.. code-block:: ruby

  .match(n: ':Person')

.. code-block:: cypher

  MATCH (n:Person)


------------

.. code-block:: ruby

  .match(n: :Person)

.. code-block:: cypher

  MATCH (n:`Person`)


------------

.. code-block:: ruby

  .match(n: [:Person, "Animal"])

.. code-block:: cypher

  MATCH (n:`Person`:`Animal`)


------------

.. code-block:: ruby

  .match(n: ' :Person')

.. code-block:: cypher

  MATCH (n:Person)


------------

.. code-block:: ruby

  .match(n: nil)

.. code-block:: cypher

  MATCH (n)


------------

.. code-block:: ruby

  .match(n: 'Person {name: "Brian"}')

.. code-block:: cypher

  MATCH (n:Person {name: "Brian"})


------------

.. code-block:: ruby

  .match(n: {name: 'Brian', age: 33})

.. code-block:: cypher

  MATCH (n {name: {n_name}, age: {n_age}})

**Parameters:** ``{:n_name=>"Brian", :n_age=>33}``

------------

.. code-block:: ruby

  .match(n: {Person: {name: 'Brian', age: 33}})

.. code-block:: cypher

  MATCH (n:`Person` {name: {n_Person_name}, age: {n_Person_age}})

**Parameters:** ``{:n_Person_name=>"Brian", :n_Person_age=>33}``

------------

.. code-block:: ruby

  .match('n--o')

.. code-block:: cypher

  MATCH n--o


------------

.. code-block:: ruby

  .match('n--o').match('o--p')

.. code-block:: cypher

  MATCH n--o, o--p


------------

#optional_match
---------------

.. code-block:: ruby

  .optional_match(n: Person)

.. code-block:: cypher

  OPTIONAL MATCH (n:`Person`)


------------

.. code-block:: ruby

  .match('m--n').optional_match('n--o').match('o--p')

.. code-block:: cypher

  MATCH m--n, o--p OPTIONAL MATCH n--o


------------

#using
------

.. code-block:: ruby

  .using('INDEX m:German(surname)')

.. code-block:: cypher

  USING INDEX m:German(surname)


------------

.. code-block:: ruby

  .using('SCAN m:German')

.. code-block:: cypher

  USING SCAN m:German


------------

.. code-block:: ruby

  .using('INDEX m:German(surname)').using('SCAN m:German')

.. code-block:: cypher

  USING INDEX m:German(surname) USING SCAN m:German


------------

#where
------

.. code-block:: ruby

  .where()

.. code-block:: cypher

  


------------

.. code-block:: ruby

  .where({})

.. code-block:: cypher

  


------------

.. code-block:: ruby

  .where('q.age > 30')

.. code-block:: cypher

  WHERE (q.age > 30)


------------

.. code-block:: ruby

  .where('q.age' => 30)

.. code-block:: cypher

  WHERE (q.age = {q_age})

**Parameters:** ``{:q_age=>30}``

------------

.. code-block:: ruby

  .where('q.age' => [30, 32, 34])

.. code-block:: cypher

  WHERE (q.age IN {q_age})

**Parameters:** ``{:q_age=>[30, 32, 34]}``

------------

.. code-block:: ruby

  .where('q.age IN {age}', age: [30, 32, 34])

.. code-block:: cypher

  WHERE (q.age IN {age})

**Parameters:** ``{:age=>[30, 32, 34]}``

------------

.. code-block:: ruby

  .where('q.name =~ ?', '.*test.*')

.. code-block:: cypher

  WHERE (q.name =~ {question_mark_param1})

**Parameters:** ``{:question_mark_param1=>".*test.*"}``

------------

.. code-block:: ruby

  .where('q.age IN ?', [30, 32, 34])

.. code-block:: cypher

  WHERE (q.age IN {question_mark_param1})

**Parameters:** ``{:question_mark_param1=>[30, 32, 34]}``

------------

.. code-block:: ruby

  .where('q.age IN ?', [30, 32, 34]).where('q.age != ?', 60)

.. code-block:: cypher

  WHERE (q.age IN {question_mark_param1}) AND (q.age != {question_mark_param2})

**Parameters:** ``{:question_mark_param1=>[30, 32, 34], :question_mark_param2=>60}``

------------

.. code-block:: ruby

  .where(q: {age: [30, 32, 34]})

.. code-block:: cypher

  WHERE (q.age IN {q_age})

**Parameters:** ``{:q_age=>[30, 32, 34]}``

------------

.. code-block:: ruby

  .where('q.age' => nil)

.. code-block:: cypher

  WHERE (q.age IS NULL)


------------

.. code-block:: ruby

  .where(q: {age: nil})

.. code-block:: cypher

  WHERE (q.age IS NULL)


------------

.. code-block:: ruby

  .where(q: {neo_id: 22})

.. code-block:: cypher

  WHERE (ID(q) = {ID_q})

**Parameters:** ``{:ID_q=>22}``

------------

.. code-block:: ruby

  .where(q: {age: 30, name: 'Brian'})

.. code-block:: cypher

  WHERE (q.age = {q_age} AND q.name = {q_name})

**Parameters:** ``{:q_age=>30, :q_name=>"Brian"}``

------------

.. code-block:: ruby

  .where(q: {age: 30, name: 'Brian'}).where('r.grade = 80')

.. code-block:: cypher

  WHERE (q.age = {q_age} AND q.name = {q_name}) AND (r.grade = 80)

**Parameters:** ``{:q_age=>30, :q_name=>"Brian"}``

------------

.. code-block:: ruby

  .where(q: {age: (30..40)})

.. code-block:: cypher

  WHERE (q.age IN RANGE({q_age_range_min}, {q_age_range_max}))

**Parameters:** ``{:q_age_range_min=>30, :q_age_range_max=>40}``

------------

#match_nodes
------------

one node object
~~~~~~~~~~~~~~~

.. code-block:: ruby

  .match_nodes(var: node_object)

.. code-block:: cypher

  MATCH var WHERE (ID(var) = {ID_var})

**Parameters:** ``{:ID_var=>246}``

------------

integer
-------

.. code-block:: ruby

  .match_nodes(var: 924)

.. code-block:: cypher

  MATCH var WHERE (ID(var) = {ID_var})

**Parameters:** ``{:ID_var=>924}``

------------

two node objects
----------------

.. code-block:: ruby

  .match_nodes(user: user, post: post)

.. code-block:: cypher

  MATCH user, post WHERE (ID(user) = {ID_user}) AND (ID(post) = {ID_post})

**Parameters:** ``{:ID_user=>246, :ID_post=>123}``

------------

node object and integer
-----------------------

.. code-block:: ruby

  .match_nodes(user: user, post: 652)

.. code-block:: cypher

  MATCH user, post WHERE (ID(user) = {ID_user}) AND (ID(post) = {ID_post})

**Parameters:** ``{:ID_user=>246, :ID_post=>652}``

------------

#unwind
-------

.. code-block:: ruby

  .unwind('val AS x')

.. code-block:: cypher

  UNWIND val AS x


------------

.. code-block:: ruby

  .unwind(x: :val)

.. code-block:: cypher

  UNWIND val AS x


------------

.. code-block:: ruby

  .unwind(x: 'val')

.. code-block:: cypher

  UNWIND val AS x


------------

.. code-block:: ruby

  .unwind(x: [1,3,5])

.. code-block:: cypher

  UNWIND [1, 3, 5] AS x


------------

.. code-block:: ruby

  .unwind(x: [1,3,5]).unwind('val as y')

.. code-block:: cypher

  UNWIND [1, 3, 5] AS x UNWIND val as y


------------

#return
-------

.. code-block:: ruby

  .return('q')

.. code-block:: cypher

  RETURN q


------------

.. code-block:: ruby

  .return(:q)

.. code-block:: cypher

  RETURN q


------------

.. code-block:: ruby

  .return('q.name, q.age')

.. code-block:: cypher

  RETURN q.name, q.age


------------

.. code-block:: ruby

  .return(q: [:name, :age], r: :grade)

.. code-block:: cypher

  RETURN q.name, q.age, r.grade


------------

.. code-block:: ruby

  .return(q: :neo_id)

.. code-block:: cypher

  RETURN ID(q)


------------

.. code-block:: ruby

  .return(q: [:neo_id, :prop])

.. code-block:: cypher

  RETURN ID(q), q.prop


------------

#order
------

.. code-block:: ruby

  .order('q.name')

.. code-block:: cypher

  ORDER BY q.name


------------

.. code-block:: ruby

  .order_by('q.name')

.. code-block:: cypher

  ORDER BY q.name


------------

.. code-block:: ruby

  .order('q.age', 'q.name DESC')

.. code-block:: cypher

  ORDER BY q.age, q.name DESC


------------

.. code-block:: ruby

  .order(q: :age)

.. code-block:: cypher

  ORDER BY q.age


------------

.. code-block:: ruby

  .order(q: [:age, {name: :desc}])

.. code-block:: cypher

  ORDER BY q.age, q.name DESC


------------

.. code-block:: ruby

  .order(q: [:age, {name: :desc, grade: :asc}])

.. code-block:: cypher

  ORDER BY q.age, q.name DESC, q.grade ASC


------------

.. code-block:: ruby

  .order(q: {age: :asc, name: :desc})

.. code-block:: cypher

  ORDER BY q.age ASC, q.name DESC


------------

.. code-block:: ruby

  .order(q: [:age, 'name desc'])

.. code-block:: cypher

  ORDER BY q.age, q.name desc


------------

#limit
------

.. code-block:: ruby

  .limit(3)

.. code-block:: cypher

  LIMIT {limit_3}

**Parameters:** ``{:limit_3=>3}``

------------

.. code-block:: ruby

  .limit('3')

.. code-block:: cypher

  LIMIT {limit_3}

**Parameters:** ``{:limit_3=>3}``

------------

.. code-block:: ruby

  .limit(3).limit(5)

.. code-block:: cypher

  LIMIT {limit_5}

**Parameters:** ``{:limit_5=>5}``

------------

#skip
-----

.. code-block:: ruby

  .skip(5)

.. code-block:: cypher

  SKIP {skip_5}

**Parameters:** ``{:skip_5=>5}``

------------

.. code-block:: ruby

  .skip('5')

.. code-block:: cypher

  SKIP {skip_5}

**Parameters:** ``{:skip_5=>5}``

------------

.. code-block:: ruby

  .skip(5).skip(10)

.. code-block:: cypher

  SKIP {skip_10}

**Parameters:** ``{:skip_10=>10}``

------------

.. code-block:: ruby

  .offset(6)

.. code-block:: cypher

  SKIP {skip_6}

**Parameters:** ``{:skip_6=>6}``

------------

#with
-----

.. code-block:: ruby

  .with('n.age AS age')

.. code-block:: cypher

  WITH n.age AS age


------------

.. code-block:: ruby

  .with('n.age AS age', 'count(n) as c')

.. code-block:: cypher

  WITH n.age AS age, count(n) as c


------------

.. code-block:: ruby

  .with(['n.age AS age', 'count(n) as c'])

.. code-block:: cypher

  WITH n.age AS age, count(n) as c


------------

.. code-block:: ruby

  .with(age: 'n.age')

.. code-block:: cypher

  WITH n.age AS age


------------

#create
-------

.. code-block:: ruby

  .create('(:Person)')

.. code-block:: cypher

  CREATE (:Person)


------------

.. code-block:: ruby

  .create(:Person)

.. code-block:: cypher

  CREATE (:Person)


------------

.. code-block:: ruby

  .create(age: 41, height: 70)

.. code-block:: cypher

  CREATE ( {age: {age}, height: {height}})

**Parameters:** ``{:age=>41, :height=>70}``

------------

.. code-block:: ruby

  .create(Person: {age: 41, height: 70})

.. code-block:: cypher

  CREATE (:`Person` {age: {Person_age}, height: {Person_height}})

**Parameters:** ``{:Person_age=>41, :Person_height=>70}``

------------

.. code-block:: ruby

  .create(q: {Person: {age: 41, height: 70}})

.. code-block:: cypher

  CREATE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>41, :q_Person_height=>70}``

------------

.. code-block:: ruby

  .create(q: {Person: {age: nil, height: 70}})

.. code-block:: cypher

  CREATE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>nil, :q_Person_height=>70}``

------------

#create_unique
--------------

.. code-block:: ruby

  .create_unique('(:Person)')

.. code-block:: cypher

  CREATE UNIQUE (:Person)


------------

.. code-block:: ruby

  .create_unique(:Person)

.. code-block:: cypher

  CREATE UNIQUE (:Person)


------------

.. code-block:: ruby

  .create_unique(age: 41, height: 70)

.. code-block:: cypher

  CREATE UNIQUE ( {age: {age}, height: {height}})

**Parameters:** ``{:age=>41, :height=>70}``

------------

.. code-block:: ruby

  .create_unique(Person: {age: 41, height: 70})

.. code-block:: cypher

  CREATE UNIQUE (:`Person` {age: {Person_age}, height: {Person_height}})

**Parameters:** ``{:Person_age=>41, :Person_height=>70}``

------------

.. code-block:: ruby

  .create_unique(q: {Person: {age: 41, height: 70}})

.. code-block:: cypher

  CREATE UNIQUE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>41, :q_Person_height=>70}``

------------

#merge
------

.. code-block:: ruby

  .merge('(:Person)')

.. code-block:: cypher

  MERGE (:Person)


------------

.. code-block:: ruby

  .merge(:Person)

.. code-block:: cypher

  MERGE (:Person)


------------

.. code-block:: ruby

  .merge(age: 41, height: 70)

.. code-block:: cypher

  MERGE ( {age: {age}, height: {height}})

**Parameters:** ``{:age=>41, :height=>70}``

------------

.. code-block:: ruby

  .merge(Person: {age: 41, height: 70})

.. code-block:: cypher

  MERGE (:`Person` {age: {Person_age}, height: {Person_height}})

**Parameters:** ``{:Person_age=>41, :Person_height=>70}``

------------

.. code-block:: ruby

  .merge(q: {Person: {age: 41, height: 70}})

.. code-block:: cypher

  MERGE (q:`Person` {age: {q_Person_age}, height: {q_Person_height}})

**Parameters:** ``{:q_Person_age=>41, :q_Person_height=>70}``

------------

#delete
-------

.. code-block:: ruby

  .delete('n')

.. code-block:: cypher

  DELETE n


------------

.. code-block:: ruby

  .delete(:n)

.. code-block:: cypher

  DELETE n


------------

.. code-block:: ruby

  .delete('n', :o)

.. code-block:: cypher

  DELETE n, o


------------

.. code-block:: ruby

  .delete(['n', :o])

.. code-block:: cypher

  DELETE n, o


------------

#set_props
----------

.. code-block:: ruby

  .set_props('n = {name: "Brian"}')

.. code-block:: cypher

  SET n = {name: "Brian"}


------------

.. code-block:: ruby

  .set_props(n: {name: 'Brian', age: 30})

.. code-block:: cypher

  SET n = {n_set_props}

**Parameters:** ``{:n_set_props=>{:name=>"Brian", :age=>30}}``

------------

#set
----

.. code-block:: ruby

  .set('n = {name: "Brian"}')

.. code-block:: cypher

  SET n = {name: "Brian"}


------------

.. code-block:: ruby

  .set(n: {name: 'Brian', age: 30})

.. code-block:: cypher

  SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

.. code-block:: ruby

  .set(n: {name: 'Brian', age: 30}, o: {age: 29})

.. code-block:: cypher

  SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.`age` = {setter_o_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30, :setter_o_age=>29}``

------------

.. code-block:: ruby

  .set(n: {name: 'Brian', age: 30}).set_props('o.age = 29')

.. code-block:: cypher

  SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.age = 29

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

.. code-block:: ruby

  .set(n: :Label)

.. code-block:: cypher

  SET n:`Label`


------------

.. code-block:: ruby

  .set(n: [:Label, 'Foo'])

.. code-block:: cypher

  SET n:`Label`, n:`Foo`


------------

.. code-block:: ruby

  .set(n: nil)

.. code-block:: cypher

  


------------

#on_create_set
--------------

.. code-block:: ruby

  .on_create_set('n = {name: "Brian"}')

.. code-block:: cypher

  ON CREATE SET n = {name: "Brian"}


------------

.. code-block:: ruby

  .on_create_set(n: {})

.. code-block:: cypher

  


------------

.. code-block:: ruby

  .on_create_set(n: {name: 'Brian', age: 30})

.. code-block:: cypher

  ON CREATE SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

.. code-block:: ruby

  .on_create_set(n: {name: 'Brian', age: 30}, o: {age: 29})

.. code-block:: cypher

  ON CREATE SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.`age` = {setter_o_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30, :setter_o_age=>29}``

------------

.. code-block:: ruby

  .on_create_set(n: {name: 'Brian', age: 30}).on_create_set('o.age = 29')

.. code-block:: cypher

  ON CREATE SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.age = 29

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

#on_match_set
-------------

.. code-block:: ruby

  .on_match_set('n = {name: "Brian"}')

.. code-block:: cypher

  ON MATCH SET n = {name: "Brian"}


------------

.. code-block:: ruby

  .on_match_set(n: {})

.. code-block:: cypher

  


------------

.. code-block:: ruby

  .on_match_set(n: {name: 'Brian', age: 30})

.. code-block:: cypher

  ON MATCH SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

.. code-block:: ruby

  .on_match_set(n: {name: 'Brian', age: 30}, o: {age: 29})

.. code-block:: cypher

  ON MATCH SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.`age` = {setter_o_age}

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30, :setter_o_age=>29}``

------------

.. code-block:: ruby

  .on_match_set(n: {name: 'Brian', age: 30}).on_match_set('o.age = 29')

.. code-block:: cypher

  ON MATCH SET n.`name` = {setter_n_name}, n.`age` = {setter_n_age}, o.age = 29

**Parameters:** ``{:setter_n_name=>"Brian", :setter_n_age=>30}``

------------

#remove
-------

.. code-block:: ruby

  .remove('n.prop')

.. code-block:: cypher

  REMOVE n.prop


------------

.. code-block:: ruby

  .remove('n:American')

.. code-block:: cypher

  REMOVE n:American


------------

.. code-block:: ruby

  .remove(n: 'prop')

.. code-block:: cypher

  REMOVE n.prop


------------

.. code-block:: ruby

  .remove(n: :American)

.. code-block:: cypher

  REMOVE n:`American`


------------

.. code-block:: ruby

  .remove(n: [:American, "prop"])

.. code-block:: cypher

  REMOVE n:`American`, n.prop


------------

.. code-block:: ruby

  .remove(n: :American, o: 'prop')

.. code-block:: cypher

  REMOVE n:`American`, o.prop


------------

.. code-block:: ruby

  .remove(n: ':prop')

.. code-block:: cypher

  REMOVE n:`prop`


------------

#start
------

.. code-block:: ruby

  .start('r=node:nodes(name = "Brian")')

.. code-block:: cypher

  START r=node:nodes(name = "Brian")


------------

.. code-block:: ruby

  .start(r: 'node:nodes(name = "Brian")')

.. code-block:: cypher

  START r = node:nodes(name = "Brian")


------------

clause combinations
-------------------

.. code-block:: ruby

  .match(q: Person).where('q.age > 30')

.. code-block:: cypher

  MATCH (q:`Person`) WHERE (q.age > 30)


------------

.. code-block:: ruby

  .where('q.age > 30').match(q: Person)

.. code-block:: cypher

  MATCH (q:`Person`) WHERE (q.age > 30)


------------

.. code-block:: ruby

  .where('q.age > 30').start('n').match(q: Person)

.. code-block:: cypher

  START n MATCH (q:`Person`) WHERE (q.age > 30)


------------

.. code-block:: ruby

  .match(q: {age: 30}).set_props(q: {age: 31})

.. code-block:: cypher

  MATCH (q {age: {q_age}}) SET q = {q_set_props}

**Parameters:** ``{:q_age=>30, :q_set_props=>{:age=>31}}``

------------

.. code-block:: ruby

  .match(q: Person).with('count(q) AS count')

.. code-block:: cypher

  MATCH (q:`Person`) WITH count(q) AS count


------------

.. code-block:: ruby

  .match(q: Person).with('count(q) AS count').where('count > 2')

.. code-block:: cypher

  MATCH (q:`Person`) WITH count(q) AS count WHERE (count > 2)


------------

.. code-block:: ruby

  .match(q: Person).with(count: 'count(q)').where('count > 2').with(new_count: 'count + 5')

.. code-block:: cypher

  MATCH (q:`Person`) WITH count(q) AS count WHERE (count > 2) WITH count + 5 AS new_count


------------

.. code-block:: ruby

  .match(q: Person).match('r:Car').break.match('(p: Person)-->q')

.. code-block:: cypher

  MATCH (q:`Person`), r:Car MATCH (p: Person)-->q


------------

.. code-block:: ruby

  .match(q: Person).break.match('r:Car').break.match('(p: Person)-->q')

.. code-block:: cypher

  MATCH (q:`Person`) MATCH r:Car MATCH (p: Person)-->q


------------

.. code-block:: ruby

  .match(q: Person).match('r:Car').break.break.match('(p: Person)-->q')

.. code-block:: cypher

  MATCH (q:`Person`), r:Car MATCH (p: Person)-->q


------------

.. code-block:: ruby

  .with(:a).order(a: {name: :desc}).where(a: {name: 'Foo'})

.. code-block:: cypher

  WITH a ORDER BY a.name DESC WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo"}``

------------

.. code-block:: ruby

  .with(:a).limit(2).where(a: {name: 'Foo'})

.. code-block:: cypher

  WITH a LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

.. code-block:: ruby

  .with(:a).order(a: {name: :desc}).limit(2).where(a: {name: 'Foo'})

.. code-block:: cypher

  WITH a ORDER BY a.name DESC LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

.. code-block:: ruby

  .order(a: {name: :desc}).with(:a).where(a: {name: 'Foo'})

.. code-block:: cypher

  WITH a ORDER BY a.name DESC WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo"}``

------------

.. code-block:: ruby

  .limit(2).with(:a).where(a: {name: 'Foo'})

.. code-block:: cypher

  WITH a LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

.. code-block:: ruby

  .order(a: {name: :desc}).limit(2).with(:a).where(a: {name: 'Foo'})

.. code-block:: cypher

  WITH a ORDER BY a.name DESC LIMIT {limit_2} WHERE (a.name = {a_name})

**Parameters:** ``{:a_name=>"Foo", :limit_2=>2}``

------------

.. code-block:: ruby

  .match(q: Person).where('q.age = {age}').params(age: 15)

.. code-block:: cypher

  MATCH (q:`Person`) WHERE (q.age = {age})

**Parameters:** ``{:age=>15}``

------------

