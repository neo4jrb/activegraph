Contributing
============

We very much welcome contributions!  Before contributing there are a few things that you should know about the neo4j.rb projects:

The Neo4j.rb Project
--------------------

We have three main gems: `neo4j <https://github.com/neo4jrb/neo4j>`_, `neo4j-core <https://github.com/neo4jrb/neo4j-core>`_, `neo4j-rake_tasks <https://github.com/neo4jrb/neo4j-rake_tasks>`_.

We try to follow semantic versioning based on `semver.org <http://semver.org/>`

Low Hanging Fruit
-----------------

Just reporting issues is helpful, but if you want to help with some code we label our GitHub issues with ``low-hanging-fruit`` to make it easy for somebody to start helping out:

https://github.com/neo4jrb/neo4j/labels/low-hanging-fruit

https://github.com/neo4jrb/neo4j-core/labels/low-hanging-fruit

https://github.com/neo4jrb/neo4j-rake_tasks/labels/low-hanging-fruit

Help or discussion on other issues is welcome, just let us know!

Communicating With the Neo4j.rb Team
------------------------------------

GitHub issues are a great way to submit new bugs / ideas.  Of course pull requests are welcome (though please check with us first if it's going to be a large change).  We like tracking our GitHub issues with waffle.io (`neo4j <https://waffle.io/neo4jrb/neo4j>`_, `neo4j-core <https://waffle.io/neo4jrb/neo4j-core>`_, `neo4j-rake_tasks <https://waffle.io/neo4jrb/neo4j-rake_tasks>`_) but just through GitHub also works.

We hang out mostly in our `Gitter.im chat room <https://gitter.im/neo4jrb/neo4j>`_ and are happy to talk or answer questions.  We also are often around on the `Neo4j-Users Slack group <http://neo4j.com/blog/public-neo4j-users-slack-group/>`_.

Running Specs
-------------

For running the specs, see our `spec/README.md <https://github.com/neo4jrb/neo4j/blob/master/spec/README.md>`_

Before you submit your pull request
-----------------------------------

Automated Tools
~~~~~~~~~~~~~~~

We use:

 * `RSpec <http://rspec.info/>`_
 * `Rubocop <https://github.com/bbatsov/rubocop>`_
 * `Coveralls <https://coveralls.io>`_

Please try to check at least the RSpec tests and Rubocop before making your pull request.  ``Guardfile`` and ``.overcommit.yml`` files are available if you would like to use ``guard`` (for RSpec and rubocop) and/or overcommit.

We also use Travis CI to make sure all of these pass for each pull request.  Travis runs the specs across multiple versions of Ruby and multiple Neo4j databases, so be aware of that for potential build failures.

Documentation
~~~~~~~~~~~~~

To aid our users, we try to keep a complete ``CHANGELOG.md`` file.  We use `keepachangelog.com <http://keepachangelog.com/>`_ as a guide.  We appreciate a line in the ``CHANGELOG.md`` as part of any changes.

We also use Sphinx / reStructuredText for our documentation which is published on `readthedocs.org <http://neo4jrb.readthedocs.org/>`_.  We also appreciate your help in documenting any user-facing changes.

Notes about our documentation setup:

 * YARD documentation in code is also parsed and placed into the Sphinx site so that is also welcome.  Note that reStructuredText inside of your YARD docs will render more appropriately.
 * You can use ``rake docs`` to build the documentation locally and ``rake docs:open`` to open it in your web browser.
 * Please make sure that you run ``rake docs`` before committing any documentation changes and checkin all changes to ``docs/``.


