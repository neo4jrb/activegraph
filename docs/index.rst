.. Neo4j.rb documentation master file, created by
   sphinx-quickstart on Mon Mar  9 22:41:19 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Neo4j.rb's documentation!
====================================

Contents:

.. toctree::
   :maxdepth: 3

   Introduction
   Setup

   RakeTasks

   ActiveNode
   ActiveRel

   Properties

   Querying

   QueryClauseMethods

   Configuration

   Contributing

   AdditionalResources

   api/index

Neo4j.rb (the `neo4j <https://github.com/neo4jrb/neo4j>`_ and `neo4j-core <https://github.com/neo4jrb/neo4j-core>`_ gems) is a `Ruby <https://www.ruby-lang.org/en/>`_ Object-Graph-Mapper (OGM) for the `Neo4j <http://neo4j.com/>`_ graph database. It tries to follow API conventions established by `ActiveRecord <http://guides.rubyonrails.org/active_record_basics.html>`_ and familiar to most Ruby developers but with a Neo4j flavor.

Ruby
  (software) A dynamic, open source programming language with a focus on simplicity and productivity. It has an elegant syntax that is natural to read and easy to write.

Graph Database
  (computer science) A graph database stores data in a graph, the most generic of data structures, capable of elegantly representing any kind of data in a highly accessible way.

Neo4j
  (databases) The world's leading graph database


If you're already familiar with ActiveRecord, DataMapper, or Mongoid, you'll find the Object Model features you've come to expect from an O*M:

 * Properties
 * Indexes / Constraints
 * Callbacks
 * Validation
 * Assocations
Because relationships are first-class citizens in Neo4j, models can be created for both nodes and relationships.

Additional features include
---------------------------

 * A chainable `arel <https://github.com/rails/arel>`_-inspired query builder
 * Transactions
 * Migration framework

Requirements
------------

 * Ruby 1.9.3+ (tested in MRI and JRuby)
 * Neo4j 2.1.0 + (version 4.0+ of the gem is required to use neo4j 2.2+)


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

