require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::MigrationMixin do

    pending
    
  def create_migration(clazz)
    clazz.migration 1, :split_name do
      # Split name into two properties
      up do
        all.each_raw do |node|
          node[:given_name] = node[:name].split[0]
          node[:surname]    = node[:name].split[1]
          node[:name]       = nil
        end
      end

      down do
        all.each_raw do |node|
          node[:name]       = "#{node[:given_name]} #{node[:surname]}"
          node[:surename]   = nil
          node[:given_name] = nil
        end
      end
    end
  end


  context Neo4j::Rails::Model do

    class PersonMigModel < Neo4j::Rails::Model
      include Neo4j::MigrationMixin
      property :name
    end

    before(:each) do
      PersonMigModel.reset_migrations!
    end

    it "#migrations should be empty when there are no migrations" do
      PersonMigModel.migrations.should be_empty
    end

    it "#migration adds migrations" do
      create_migration(PersonMigModel)
      PersonMigModel.migrations.size.should == 1
    end

    it "#migrate runs all migrations" do
      kalle = PersonMigModel.create! :name => 'kalle stropp'

      class PersonMigModel
        property :surname
        property :given_name
      end

      create_migration(PersonMigModel)

      # when
      PersonMigModel.migrate!

      # then
      k2 = Neo4j::Node.load(kalle.neo_id)
      k2.surname.should == 'stropp'
      k2.given_name.should == 'kalle'
    end
  end


  context Neo4j::NodeMixin,  :type => :transactional  do
    class PersonInfo
      include Neo4j::NodeMixin
      include Neo4j::MigrationMixin
      rule :all
      property :name
    end

    before(:each) do
      PersonInfo.reset_migrations!
    end

    it "migrates when the node is loaded" do
      kalle = PersonInfo.new :name => 'kalle stropp'
      finish_tx

      class PersonInfo
        property :surname
        property :given_name
      end

      create_migration(PersonInfo)

      # when
      PersonInfo.migrate!

      # then
      k2 = Neo4j::Node.load(kalle.neo_id)
      k2.surname.should == 'stropp'
      k2.given_name.should == 'kalle'
    end
  end

end


