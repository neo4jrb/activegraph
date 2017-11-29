Query Examples
==============

In the rest of the documentation for this site we try to lay out all of the pieces of the Neo4j.rb gems to explain them one at a time.  Sometimes, though, it can be instructive to see examples.  The following are examples of code where somebody had a question and the resulting code after fixes / refactoring.  This section will expand over time as new examples are found.

Example 1: Find all contacts for a user two hops away, but don't include contacts which are only one hop away
-------------------------------------------------------------------------------------------------------------

.. code-block:: ruby

    user.contacts(:contact, :knows, rel_length: 2).where_not(
      uuid: user.contacts.pluck(:uuid)
    )

This works, though it makes two queries.  The first to get the ``uuid`` s for the ``where_not`` and the second for the full query.  For the first query, ``user.contacts.pluck(:id)`` could be also used instead, though associations already have a pre-defined method to get IDs, so this could instead be ``user.contact_ids``.

This doesn't take care of the problem of having two queries, though.  If we keep the ``rel_length: 2``, however, we won't be able to reference the nodes which are one hop away in order.  This seems like it would be a straightforward solution:

.. code-block:: ruby

    user.contacts(:contact1).contacts(:contact2).where_not('contact1 = contact2')

And it is straightforward, but it won't work.  Because Cypher matches one subgraph at a time (in this case roughly ``(:User)--(contact1:User)--(contact2:User)``), ``contact`` one is always just going to be the node which is in between the user in question and ``contact2``.  It doesn't represent "all users which are one step away".  So if we want to do this as one query, we do need to first get all of the first-level nodes together so that we can then check if the second level nodes are in that list.  This can be done as:

.. code-block:: ruby

    user.as(:user).contacts
      .query_as(:contact).with(:user, first_level_ids: 'collect(ID(contact))')
      .proxy_as(User, :user)
      .contacts(:other_contact, nil, rel_length: 2)
      .where_not('ID(other_contact) IN first_level_ids')

And there we have a query which is much more verbose than the original code, but accomplishes the goal in a single query.  Having two queries isn't neccessarily bad, so the code's complexity should be weighed against how both versions perform on real datasets.


Example 2: Simple Recommendation Engine
---------------------------------------

If you are interested in more complex collaborative filter methods check out this `article <https://neo4j.com/blog/collaborative-filtering-creating-teams/>`_.

Let's assume you have the following schema:

.. code-block:: cypher

    (:User)-[:FOLLOW|:SKIP]->(:Page)

We want to recommend pages for a user to follow based on their current followed pages.

Constraints:

- We want to include the source of the recommendation. i.e (we recommend you follow X because you follow Y).

  *Note* : To do this part, we are going to use an `APOC <https://neo4j-contrib.github.io/neo4j-apoc-procedures/index33.html>`_ function ``apoc.coll.sortMaps``.
- We want to exclude pages the user has skipped or already follows.
- The recommended pages must have a name field.

Given our schema, we could write the following Cypher to accomplish this:

.. code-block:: cypher

    MATCH (user:User { id: "1" })
    MATCH (user)-[:FOLLOW]->(followed_page:Page)<-[:FOLLOW]-(co_user:User)
    MATCH (co_user)-[:FOLLOW]->(rec_page:Page)
    WHERE exists(rec_page.name)
    AND NOT (user)-[:FOLLOW|:SKIP]->(rec_page)
    WITH rec_page, count(rec_page) AS score, collect(followed_page.name) AS source_names
    ORDER BY score DESC LIMIT {limit}
    UNWIND source_names AS source_name
    WITH rec_page, score, source_name, count(source_name) AS contrib
    WITH rec_page, score, apoc.coll.sortMaps(collect({name:source_name, contrib:contrib*-1}), 'contrib') AS sources
    RETURN rec_page.name AS name, score, extract(source IN sources[0..3] | source.name) AS top_sources,
      size(sources) AS sources_count
    ORDER BY score DESC

Now let's see how we could write this using ActiveNode syntax in a ``User`` Ruby class.

.. code-block:: ruby

    class User
      include Neo4j::ActiveNode

      property :id, type: Integer

      has_many :out, :followed_pages, type: :FOLLOW, model_class: :Page
      has_many :out, :skipped_pages, type: :SKIP, model_class: :Page

      def recommended_pages
        as(:user)
          .followed_pages(:followed_page)
            .where("exists(followed_page.name)")
          .followers(:co_user)
          .followed_pages
          .query_as(:rec_page) # Transition into Core Query
            .where("exists(rec_page.name)")
            .where_not("(user)-[:FOLLOW|:SKIP]->(rec_page)")
          .with("rec_page, count(rec_page) AS score, collect(followed_page.name) AS source_names")
            .order_by('score DESC').limit(25)
          .unwind(source_name: :source_names) # This generates "UNWIND source_names AS source_name"
          .with("rec_page, score, source_name, count(source_name) AS contrib")
          .with("rec_page, score, apoc.coll.sortMaps(collect({name:source_name,contrib:contrib*-1}), 'contrib') AS sources")
          .with("rec_page.name AS name, score, extract(source in sources[0..3] | source.name) AS top_sources, size(sources) AS sources_count")
            .order_by('score DESC')
          .pluck(:name, :score, :top_sources, :sources_count)
      end
    end

*Note* : The `contrib*-1` value is a way of getting the desired order out of the `sortMaps` APOC function without needing to reverse the resulting list.

This assumes we have a ``Page`` class like the following:

.. code-block:: ruby

    class Page
      include Neo4j::ActiveNode

      property name, type: String

      has_many :in, :followers, type: :FOLLOW, model_class: :User
      has_many :in, :skippers, type: :SKIP, model_class: :User
    end
