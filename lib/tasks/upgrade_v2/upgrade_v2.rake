require File.join(File.dirname(__FILE__), "lib", "upgrade_v2")

namespace(:neo4j) do

  desc "upgrade to 2.0.0, rename relationships"
  task :upgrade_v2 => :environment do
    Neo4j::UpgradeV2.migrate_all!
  end
end
