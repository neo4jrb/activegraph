require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Migrations::LazyNodeMixin do
  before(:each) do
    Neo4j.threadlocal_ref_node = nil    
  end

  def create_lazy_migration(clazz)
    clazz.migration 1, :split_name do
      # Split name into two properties
      up do
        self[:name]
        self[:given_name] = self[:name].split[0]
        self[:surname]    = self[:name].split[1]
        self[:name]      = nil
      end

      down do
        self.name       = "#{self[:given_name]} #{self[:surname]}"
        self.surename   = nil
        self.given_name = nil
      end
    end
  end


  context Neo4j::Rails::Model do
    class LazyPersonModel < Neo4j::Rails::Model
      include Neo4j::Migrations::LazyNodeMixin
      property :name
    end

    after(:each) { LazyPersonModel.reset_migrations!}

    it "#migrate_to" do
      LazyPersonModel.should respond_to(:migrate_to)
    end

    it "does not set the version if there are no migrations" do
      LazyPersonModel.create!.db_version.should be_nil
    end

    it "update the version when migrations has been performed" do
      p = LazyPersonModel.create!
      LazyPersonModel.migration 1, :first do
        up {|*|}
        down {|*|}
      end
      LazyPersonModel.migration 2, :second do
        up {|*|}
        down {|*|}
      end

      loaded = Neo4j::Node.load(p.id)
      loaded.db_version.should == 2
    end

    it "sets the db_version to the current migration number when a new is created" do
      create_lazy_migration(LazyPersonModel)
      kalle = LazyPersonModel.create! :name => 'kalle stropp'
      kalle.db_version.should == 1
    end

    it "does not sets the db_version if there are no migrations" do
      kalle = LazyPersonModel.create! :name => 'kalle stropp'
      kalle.db_version.should be_nil
    end

    it "migrates when the node is loaded" do
      kalle = LazyPersonModel.create! :name => 'kalle stropp'

      class LazyPersonModel
        property :surname
        property :given_name
      end

      create_lazy_migration(LazyPersonModel)

      # when
      k2 = Neo4j::Node.load(kalle.neo_id)

      # then
      k2._java_node[:surname].should == 'stropp'
      k2[:surname].should == 'stropp'
      k2[:given_name].should == 'kalle'
      k2.surname.should == 'stropp'
    end

  end

  context Neo4j::NodeMixin, :type => :transactional do
    class LazyPersonInfo
      include Neo4j::NodeMixin
      include Neo4j::Migrations::LazyNodeMixin
      property :name
    end

    it "migrates when the node is loaded" do
      kalle = LazyPersonInfo.new :name => 'kalle stropp'
      finish_tx

      class LazyPersonInfo
        property :surname
        property :given_name
      end

      create_lazy_migration(LazyPersonInfo)


      # when
      k2 = Neo4j::Node.load(kalle.neo_id)

      # then
      k2.surname.should == 'stropp'
      k2.given_name.should == 'kalle'
    end
  end
end

