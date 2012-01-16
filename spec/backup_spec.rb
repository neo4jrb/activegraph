require File.join(File.dirname(__FILE__), 'spec_helper')

describe Neo4j, " with neo4j-enterprise edition"do

  describe "Backup enabled" do
    after(:all) do
      Neo4j.shutdown
    end

    it "can do a backup", :edition => :enterprise  do
      # TODO this spec does not run together with other specs
      # We need to start neo4j in a separate process I think
      # like see: https://github.com/neo4j/enterprise/blob/master/backup/src/test/java/org/neo4j/backup/TestBackupToolEmbedded.java
      Neo4j::Config['enable_online_backup'] = 'true'
      backup_source_dir = File.join(Dir.tmpdir, "neo4j_backup_source")
      backup_target_dir = File.join(Dir.tmpdir, "neo4j_backup_target")
      FileUtils.rm_rf backup_source_dir
      FileUtils.rm_rf backup_target_dir

      Thread.new do
        Neo4j::Config[:storage_path] = backup_source_dir
        Neo4j.start
        Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j-rspec-db")
        Neo4j::Transaction.run { Neo4j.ref_node[:ko] = 'fo' }
        5.times { puts "Sleep"; sleep 1 }
      end
      sleep 2 # make sure neo4j starts
      Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j-rspec-db")
      org.neo4j.backup.OnlineBackup.from('localhost').full(backup_target_dir)
      File.exist?(backup_target_dir).should be_true
    end
  end
end