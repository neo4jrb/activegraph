# Welcome to Active Graph (f.k.a. Neo4j.rb)

## Code Status

[![Actively Maintained](https://img.shields.io/badge/Maintenance%20Level-Actively%20Maintained-green.svg)](https://gist.github.com/cheerfulstoic/d107229326a01ff0f333a1d3476e068d)
[![Build Status](https://secure.travis-ci.org/neo4jrb/neo4j.svg?branch=master)](http://travis-ci.org/neo4jrb/neo4j)
[![Coverage Status](https://coveralls.io/repos/neo4jrb/neo4j/badge.svg?branch=master)](https://coveralls.io/r/neo4jrb/neo4j?branch=master)
[![Code Climate](https://codeclimate.com/github/neo4jrb/neo4j.svg)](https://codeclimate.com/github/neo4jrb/neo4j)

## Get Support

### Documentation

All new documentation will be done via our [readthedocs](http://neo4jrb.readthedocs.org) site, though some old documentation has yet to be moved from our [wiki](https://github.com/neo4jrb/neo4j/wiki) 

### Contact Us

  [![StackOverflow](https://img.shields.io/badge/StackOverflow-Ask%20a%20question!-blue.svg)](http://stackoverflow.com/questions/ask?tags=neo4j.rb+neo4j+ruby)  [![Gitter](https://img.shields.io/badge/Gitter-Join%20our%20chat!-blue.svg)](https://gitter.im/neo4jrb/neo4j?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)  [![Twitter](https://img.shields.io/badge/Twitter-Tweet%20with%20us!-blue.svg)](https://twitter.com/neo4jrb)



# Introduction

Neo4j.rb is an Active Model compliant Ruby/JRuby wrapper for [the Neo4j graph database](http://www.neo4j.org/). It uses the [neo4j-ruby-driver](https://github.com/neo4jrb/neo4j-ruby-driver) and [active_attr](https://github.com/cgriego/active_attr) gems.

Neo4j is a transactional, open-source graph database.  A graph database manages data in a connected data structure, capable of  representing any kind of data in a very accessible way.  Information is stored in nodes and relationships connecting them, both of which can have arbitrary properties.  To learn more visit [What is a Graph Database?](http://neo4j.com/developer/graph-database/)

With this gem you not only do you get a convenient higher level wrapper around Neo4j, but you have access to a powerful high-level query building interface which lets you take advantage of the power of Neo4j like this:

```ruby
# Break down the top countries where friends' favorite beers come from
person.friends.favorite_beers.country_of_origin(:country).
  order('count(country) DESC').
  pluck(:country, count: 'count(country)')
```

It can be installed in your `Gemfile` with a simple `gem 'neo4j'`

For a general overview see our website: http://neo4jrb.io/

Winner of a 2014 Graphie for "Best Community Contribution" at Neo4j's [Graph Connect](http://graphconnect.com) conference!
![2014 Graphie](http://i.imgur.com/CkOoTTYm.jpg)

Neo4j.rb v4.1.0 was released in January of 2015. Its changes are outlined [here](https://github.com/neo4jrb/neo4j/wiki/Neo4j.rb-v4-Introduction) and in the [announcement message](http://neo4jrb.io/blog/2015/01/09/neo4j-rb_v4-1_released.html). It will take a little time before all documentation is updated to reflect the new release but unless otherwise noted, all 3.X documentation is totally valid for v4.

## Neo4j version support

| **Neo4j Version** | v2.x | v3.x  | >= v4.x | >= 7.0.3 | activegraph 10.0 |
|-------------------|------|-------|---------|----------|------------------|
| 1.9.x             | Yes  | No    | No      | No       | No               |
| 2.0.x             | No   | Yes   | No      | No       | No               |
| 2.1.x             | No   | Yes   | Yes *   | Yes      | No               |
| 2.2.x             | No   | No    | Yes     | Yes      | No               |
| 2.3.x             | No   | No    | Yes     | Yes      | No               |
| 3.0, 3.1, 3.3     | No   | No    | No      | Yes      | No               |
| 3.4, 3.5          | No   | No    | No      | Yes      | Yes              |
| 4.0               | No   | No    | No      | No       | Yes              |
| 4.1               | No   | No    | No      | No       | No               |

`*` Neo4j.rb >= 4.x doesn't support Neo4j versions before 2.1.5.  To use 2.1.x you should upgrade to a version >= 2.1.5

## Neo4j feature support

| **Neo4j Feature**          |   v2.x | v3.x | >= v4.x | >= 8.x | activegraph 10.0 |
|----------------------------|--------|------|---------|--------|------------------|
| Bolt Protocol              |   No   |  No  | No      | Yes    | Yes              | 
| Auth                       |   No   |  No  | Yes     | Yes    | Yes              |
| Remote Cypher              |   Yes  |  Yes | Yes     | Yes    | No               |
| Transactions               |   Yes  |  Yes | Yes     | Yes    | Yes              |
| High Availability          |   No   |  Yes | Yes     | Yes    | Yes              |
| Causal Cluster             |   No   |  No  | No      | No     | Yes              |
| Embedded JVM support       |   Yes  |  Yes | Yes     | Yes    | via bolt only    |

## Documentation

* [Website](http://neo4jrb.io/) (for an introduction)
* [readthedocs](http://neo4jrb.readthedocs.io/)
* **Note:** Our GitHub Wiki pages have outdated information.  We are in the process of moving all documentation to [readthedocs](http://neo4jrb.readthedocs.io/)

## Legacy (<= 2.x) Documentation

* [README](https://github.com/neo4jrb/neo4j/tree/2.x)
* [Wiki](https://github.com/neo4jrb/neo4j/wiki/Neo4j%3A%3ARails-Introduction)

## Developers

### Original Author

* [Andreas Ronge](https://github.com/andreasronge)

### Previous Maintainers

* [Brian Underwood](https://github.com/cheerfulstoic)
* [Chris Grigg](https://github.com/subvertallchris)

### Current Maintainers

* [Heinrich Klobuczek](https://github.com/klobuczek)
* [Amit Suryavanshi](https://github.com/amitsuryavanshi)

## Contributing

Always welcome!  Please review the [guidelines for contributing](CONTRIBUTING.md) to this repository.

## License

* Neo4j.rb - MIT, see the [LICENSE](http://github.com/andreasronge/neo4j/tree/master/LICENSE).
* Neo4j - Dual free software/commercial license, see [Licensing Guide](http://www.neo4j.org/learn/licensing).

**Notice:** There are different licenses for the `neo4j-community`, `neo4j-advanced`, and `neo4j-enterprise` jar gems. Only the `neo4j-community` gem is required by default.

