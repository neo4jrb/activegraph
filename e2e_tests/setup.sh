#!/bin/sh

# Example values of environment variables ACTIVE_MODEL_VERSION=7.1.3 ACTIVEGRAPH_PATH=../ E2E_PORT=7687 E2E_NO_CRED=true

rm -r ./myapp
gem install rails -v $ACTIVE_MODEL_VERSION --no-document

sed 's|.*gem '"'"'activegraph'"'"'.*|gem '"'"'activegraph'"'"', path: '"'"'../'"'"'|' docs/activegraph.rb > template.tmp

rails \_$ACTIVE_MODEL_VERSION\_ new myapp -O -m ./template.tmp
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

echo "Generating model"
bundle exec rails generate model User name:string
echo "Generating migration"
bundle exec rails generate migration BlahMigration
echo "Running migration"
bundle exec rake neo4j:migrate

if echo 'puts "Starting rails console"' | bundle exec rails c
then
  echo "Rails console works correctly"
else
  echo "Rails console didn't start"
  exit 1
fi

echo "Starting rails server"
bundle exec rails s &
until $(curl --output /dev/null --silent --head --fail localhost:3000); do
  printf '.'
  sleep 1
done
kill `cat tmp/pids/server.pid`
