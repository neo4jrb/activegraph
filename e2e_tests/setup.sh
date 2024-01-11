#!/bin/sh

echo "SHA=$(git rev-parse --short "$GITHUB_SHA")" >> $GITHUB_ENV
gem install rails -v 7.1.2 --no-document
# /Users/hardik_joshi/work/open_source/activegraph/docs/activegraph.rb
sed 's/.*activegraph.*/gem '"'"'activegraph'"'"', github: "neo4jrb\/activegraph", ref: '"$SHA"'/' docs/activegraph.rb > template.tmp
rails _7.1.2_ new myapp -O -m ./template.tmp
cd myapp
bundle exec rails generate model User name:string
# RAILS_ENV=test bundle exec rake neo4j:migrate
# bundle exec rails c
# bundle exec rails s

