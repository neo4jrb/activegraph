# Welcome to Neo4j.rb

## Status

[![Build Status](https://secure.travis-ci.org/neo4jrb/neo4j.png?branch=master)](http://travis-ci.org/neo4jrb/neo4j) [![Coverage Status](https://coveralls.io/repos/neo4jrb/neo4j/badge.png?branch=master)](https://coveralls.io/r/neo4jrb/neo4j?branch=master) [![Code Climate](https://codeclimate.com/github/neo4jrb/neo4j.png)](https://codeclimate.com/github/neo4jrb/neo4j) [![PullReview stats](https://www.pullreview.com/github/neo4jrb/neo4j/badges/master.svg?)](https://www.pullreview.com/github/neo4jrb/neo4j/reviews/master)

# Get Support

[![New GitHub Issue](https://img.shields.io/badge/Bug%3F-Post%20an%20issue!-blue.svg)](https://github.com/neo4jrb/neo4j/issues/new)  [![StackOverflow](https://img.shields.io/badge/StackOverflow-Ask%20a%20question!-blue.svg)](http://stackoverflow.com/questions/ask?tags=neo4j.rb)  [![Gitter](https://img.shields.io/badge/Gitter-Join%20our%20chat!-blue.svg)](https://gitter.im/neo4jrb/neo4j?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)  [![Twitter](https://img.shields.io/badge/Twitter-Tweet%20with%20us!-blue.svg)](https://twitter.com/neo4jrb)  [![Mailing list](https://img.shields.io/badge/Mailing%20list-Mail%20us!-blue.svg)](https://groups.google.com/forum/#!forum/neo4jrb)

# Introduction

Neo4j.rb is an Active Model compliant Ruby/JRuby wrapper for [the Neo4j graph database](http://www.neo4j.org/). It uses the [neo4j-core](https://github.com/neo4jrb/neo4j-core) and [active_attr](https://github.com/cgriego/active_attr) gems.

With this gem you not only do you get a convenient higher level wrapper around Neo4j, but you have access to a powerful high-level query building interface which lets you take advantage of the power of Neo4j like this:

    # Break down the top countries where friends' favorite beers come from
    person.friends.favorite_beers.country_of_origin(:country).order('count(country) DESC').pluck(:country, count: 'count(country)')

For a general overview see our website: http://neo4jrb.io/

Winner of a 2014 Graphie for "Best Community Contribution" at Neo4j's [Graph Connect](http://graphconnect.com) conference!
![2014 Graphie](http://i.imgur.com/CkOoTTYm.jpg)

Neo4j.rb v4.1.0 was released in January of 2015. Its changes are outlined [here](https://github.com/neo4jrb/neo4j/wiki/Neo4j.rb-v4-Introduction) and in the [announcement message](http://neo4jrb.io/blog/2015/01/09/neo4j-rb_v4-1_released.html). It will take a little time before all documentation is updated to reflect the new release but unless otherwise noted, all 3.X documentation is totally valid for v4.

## Modern (3.x/4.X) Documentation

* [Website](http://neo4jrb.io/) (for an introduction)
* [Wiki](https://github.com/neo4jrb/neo4j/wiki/Neo4j.rb-v4-Introduction)

## Legacy (2.x) Documentation

* [README](https://github.com/neo4jrb/neo4j/tree/2.x)
* [Wiki](https://github.com/neo4jrb/neo4j/wiki/Neo4j%3A%3ARails-Introduction)

## Support

* Open an [issue](https://github.com/neo4jrb/neo4j/issues), post to [Stack Overflow](http://stackoverflow.com/questions/tagged/neo4j+ruby), or contact one of the developers.
* [Neo4j.rb mailing list](https://groups.google.com/forum/#!forum/neo4jrb)

## Developers

### Original Author

* [Andreas Ronge](https://github.com/andreasronge)

### Current Maintainers

* [Brian Underwood](https://github.com/cheerfulstoic)
* [Chris Grigg](https://github.com/subvertallchris)

* Consulting support? Contact [Chris](http://subvertallmedia.com/) and/or [Brian](http://www.brian-underwood.codes/)

## Contributing

Always welcome!  Please review the [guidelines for contributing](CONTRIBUTING.md) to this repository.

## License

* Neo4j.rb - MIT, see the [LICENSE](http://github.com/andreasronge/neo4j/tree/master/LICENSE).
* Neo4j - Dual free software/commercial license, see [Licensing Guide](http://www.neo4j.org/learn/licensing).

**Notice:** There are different licenses for the `neo4j-community`, `neo4j-advanced`, and `neo4j-enterprise` jar gems. Only the `neo4j-community` gem is required by default.
