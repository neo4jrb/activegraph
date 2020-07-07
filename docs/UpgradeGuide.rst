Upgrade Guide
=============

This guide outlines changes from the last ``neo4j``` gem version 9.x to ``activegraph`` version 10.x.

``activegraph`` is an extensive refactoring of the ``neo4j`` gem. The major changes comprise of:

 * full bolt support
 * full causal cluster support
 * removal of http support
 * removal of embedded support (neo4j embedded is still supported via bolt)
 * support for a neo4j ruby driver with an api of the official drivers
 * discontinuation of the ``neo4j-core`` gem. Its functionality is replaced partially by ``neo4j-ruby-driver`` and
   partially by ``activegraph``
 * higher naming consistency with ``activerecord`` and the official ``neo4j-java-driver``
 * configuration more consistent with ``activerecord``
 * changed transaction API
 * support for sessions with bookmarks and read and write transaction

How to upgrade to ``activegraph``?
----------------------------------

Your `neo4j` application is unlikely to work with ``activegraph`` out of the box. The good news is that the changes
required are rather straightforward. To start follow the Setup guide. Once configured there few class name changes:

 * Neo4j::ActiveNode became ActiveGraph::Node
 * Neo4j::AciveRel became ActiveGrah::Relationship
 * Neo4j::ActiveBase became ActiveGrapph::Base
 * all other classes changed their namespace from Neo4j to ActiveGraph

If you use explicit cypher with ``{parameter}`` syntax you will need to change it to ``$parameter`` if using neo4j 4

Transaction API
^^^^^^^^^^^^^^^

The previous transaction api has been modified to support causal cluster and be a bit more intutive to ``activerecord``
users. The following methods provide that api:

 * ActiveGraph::Base.session - corresponds to driver's session, if called multiple times from the same thread will use the same instance
 * ActiveGraph::Base.transaction - corresponds to driver's begin_transaction, the most basic way of creating transactions
 * ActiveGraph::Base.read_transaction - corresponds to a driver read_transaction, with retry logic, routed to a follower or read replica
 * ActiveGraph::Base.write_transaction - corresponds to a driver witer_transaction, with retry logic, routed to the leader

All the above methods can be called on concrete model classes as well.


Exceptions
^^^^^^^^^^

Several Exception types which previously were defined in the ```neo4j`` gem have been replaced with neo4j driver
exceptions.

