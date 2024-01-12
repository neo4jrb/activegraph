#!/bin/sh

echo "SHA=$(git rev-parse "$GITHUB_SHA")" >> $GITHUB_ENV
gem install rails -v 7.1.2 --no-document
sed 's/.*gem '"'"'activegraph'"'"'.*/gem '"'"'activegraph'"'"', github: "neo4jrb\/activegraph", ref: "'"$(git rev-parse "$GITHUB_SHA")"'"/' docs/activegraph.rb > template.tmp
rails _7.1.2_ new myapp -O -m ./template.tmp
cd myapp
bundle exec rails generate model User name:string
RAILS_ENV=test bundle exec rake neo4j:migrate
# bundle exec rails c
# bundle exec rails s

