#!/bin/sh

if [[ -n "$ACTIVE_MODEL_VERSION" ]]
then
  gem install rails -v $ACTIVE_MODEL_VERSION --no-document
else
  gem install rails -v 7.1.2 --no-document
fi

if [[ -n "$SHA" ]]
then
  sed 's/.*gem '"'"'activegraph'"'"'.*/gem '"'"'activegraph'"'"', github: "neo4jrb\/activegraph", ref: "'"$SHA"'"/' docs/activegraph.rb > template.tmp
else
  echo "SHA=$(git rev-parse "$GITHUB_SHA")" >> $GITHUB_ENV
  sed 's/.*gem '"'"'activegraph'"'"'.*/gem '"'"'activegraph'"'"', github: "neo4jrb\/activegraph", ref: "'"$(git rev-parse "$GITHUB_SHA")"'"/' docs/activegraph.rb > template.tmp
fi
rails _7.1.2_ new myapp -O -m ./template.tmp
rm -f ./template.tmp
cd myapp

if [[ -n "$E2E_PORT" ]]
then
  sed 's/7687/'$E2E_PORT'/' config/environments/development.rb > dev_env.tmp
  mv dev_env.tmp config/environments/development.rb
fi

if [[ -n "$E2E_NO_CRED" ]]
then
  sed "s/'neo4j'/''/" config/environments/development.rb > dev_env.tmp
  mv dev_env.tmp config/environments/development.rb
  sed "s/'password'/''/" config/environments/development.rb > dev_env.tmp
  mv dev_env.tmp config/environments/development.rb
fi

bundle exec rails generate model User name:string
bundle exec rails generate migration BlahMigration
bundle exec rake neo4j:migrate
if echo 'puts "hi"' | bundle exec rails c
then
  echo "rails console works correctly"
else
  exit 1
fi
bundle exec rails s -d
# while [ $((curl localhost:3000/ > /dev/null 2>&1); echo $?) -ne 0 ]; do sleep 1; done
until $(curl --output /dev/null --silent --head --fail localhost:3000); do
  printf '.'
  sleep 2
done
kill `cat tmp/pids/server.pid`
