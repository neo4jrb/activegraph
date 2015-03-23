
# Getting help

If you have a bug or a feature, we welcome new issues.  We also answer questions on StackOverflow (use the `neo4j.rb` tag) and are generally around on [Gitter](https://gitter.im/neo4jrb/neo4j)

# Code standards

Pull request with high test coverage and good [code climate](https://codeclimate.com/github/neo4jrb/neo4j) values will be accepted faster.

# Rubocop

We use [rubocop](https://github.com/bbatsov/rubocop) for sanity checks to make sure our code doesn't get too ugly.  Because of this, a pull request can fail on Travis CI when the specs all run fine.  We recommend installing [overcommit](https://github.com/causes/overcommit) so that rubocop is run is pre-commit hooks so that this causes minimal frustration.  We already have an overcommit configuration, so you simply need to run `overcommit --install` to set up the git hooks.  A `Guardfile` is also provided so that you can use rspec and rubocop continuously while working.

# Travis CI

We use Travis CI to test across multiple verisons of ruby and versions of Neo4j, so please watch for failures there.
