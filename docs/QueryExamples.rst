Query Examples
==============

In the rest of the documentation for this site we try to lay out all of the pieces of the Neo4j.rb gems to explain them one at a time.  Sometimes, though, it can be instructive to see examples.  The following are examples of code where somebody had a question and the resulting code after fixes / refactoring.  This section will expand over time as new examples are found.

Goal: Find all contacts for a user two hops away, but don't include contacts which are only one hop away
--------------------------------------------------------------------------------------------------------

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
