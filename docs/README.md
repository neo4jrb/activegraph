The Neo4j.rb docs!

This directory is a sphinx project designed to work with https://readthedocs.org/

There is a set of static *.rst files which provide tutorial-style overview documentation for the Neo4j.rb project.  In addition there are [YARD](http://yardoc.org/) templates which output the API documentation from the comments in the Ruby source code to *.rst files under the `api` directory.


# Rake tasks

## `rake docs:yard`

Run YARD to build the `api` docs directory.  This wipes and rebuilds the `docs/_build/_yard` directory.  The YARD templates which output RST files are under `docs/_yard/custom_templates`

## `rake docs:sphinx`

Builds the sphinx RST files into HTML documentation.  This includes wiping and rebuilding the `docs/api` directory from `docs/_build/_yard`.  The output directory is `docs/_build/html`

## `rake docs`

Run `docs:yard` and then `docs:sphinx`

## `rake docs:open`

Shortcut to open `docs/_build/html/index.html` in your browser

