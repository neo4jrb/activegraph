#!/bin/sh

gem install rails -v 7.1.2 --no-document
if [[ -n "$SHA" ]]
then
  sed 's/.*gem '"'"'activegraph'"'"'.*/gem '"'"'activegraph'"'"', github: "neo4jrb\/activegraph", ref: "'"$SHA"'"/' docs/activegraph.rb > template.tmp
else
  echo "SHA=$(git rev-parse "$GITHUB_SHA")" >> $GITHUB_ENV
  sed 's/.*gem '"'"'activegraph'"'"'.*/gem '"'"'activegraph'"'"', github: "neo4jrb\/activegraph", ref: "'"$(git rev-parse "$GITHUB_SHA")"'"/' docs/activegraph.rb > template.tmp
fi
rails _7.1.2_ new myapp -O -m ./template.tmp
cd myapp
bundle exec rails generate model User name:string
bundle exec rake neo4j:migrate
if echo 'puts "hi"' | bundle exec rails c
then
  echo "rails console works correctly"
else
  exit 1
fi
bundle exec rails s -d
while [ $((curl localhost:3000/ > /dev/null 2>&1); echo $?) -ne 0 ]; do sleep 1; done
kill `cat tmp/pids/server.pid`


