require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Migrations::NodeMixin do

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

  context "unmanaged transaction" do

    def create_migration_without_tx_fail(clazz)
      clazz.migration 1, :split_name do
        auto_transaction false # let use create the transaction instead
        up do
          Neo4j.ref_node[:bla] = 'bla'
        end

        down do
          Neo4j.ref_node[:bla] = 'bloj'
        end
      end
    end

    def create_migration_without_tx_success(clazz)
      clazz.migration 1, :split_name do
        auto_transaction false # let use create the transaction instead
        up do
          Neo4j::Transaction.run do
            Neo4j.ref_node[:bla] = 'bla'
          end
        end

        down do
          Neo4j::Transaction.run do
            Neo4j.ref_node[:bla] = 'bloj'
          end
        end
      end
    end

    it "#migrate! should raise an exception if the migration did not create a Transaction" do
      clazz = create_node_mixin do
        include Neo4j::Migrations::NodeMixin
      end

      create_migration_without_tx_fail(clazz)

      # when
      lambda { clazz.migrate! }.should raise_error

      clazz.db_version.should be_nil
    end

    it "#migrate! should NOT raise an exception if the migration did create a Transaction" do
      clazz = create_node_mixin do
        include Neo4j::Migrations::NodeMixin
      end

      create_migration_without_tx_success(clazz)

      # when
      lambda { clazz.migrate! }.should_not raise_error

      clazz.db_version.should == 1
      Neo4j.ref_node[:bla].should == 'bla'
    end

  end

  context "one migration with a rule" do
    context Neo4j::NodeMixin, :type => :transactional do
      it "can add rule :all on existing nodes" do
        clazz = create_node_mixin do
          include Neo4j::Migrations::NodeMixin
        end
        # create nodes with out
        a = clazz.new :name =>'a'
        b = clazz.new :name =>'b'
        finish_tx

        clazz.should_not respond_to(:all)

        # add the rule :all
        clazz.instance_eval do
          rule :all
        end
        clazz.migration 1, :add_all_rule do
          up do
            Neo4j.all_nodes.each do |node|
              clazz.trigger_rules(node)
            end
          end
        end

        clazz.migrate!

        clazz.all.should include(a,b)
      end

      it "can add a counter after the nodes has been created" do
        clazz = create_node_mixin do
          include Neo4j::Migrations::NodeMixin
          rule :all
        end
        # create nodes with out counter
        a = clazz.new :name =>'a'
        b = clazz.new :name =>'b'
        finish_tx

        rule_node_props = Neo4j::Rule::Rule.rule_node_for(clazz).rule_node.props
        rule_node_props.should_not include(:sum)
        rule_node_props['_count_all__classname'].should be_nil

        clazz.instance_eval do
          rule(:all, :functions => Neo4j::Rule::Functions::Count.new)
        end

        clazz.migration 1, :add_count_rule do
          up do
            func = clazz.add_function_for(:all, Neo4j::Rule::Functions::Count)
            clazz.all.each do |node|
              func.call(node)
            end
          end
        end
        clazz.migrate!
        rule_node_props = Neo4j::Rule::Rule.rule_node_for(clazz).rule_node.props
        #"_#{function_name}_#{rule_name}_#{prop}"
        rule_node_props['_count_all__classname'].should == 2
        clazz.all.to_a.size.should == 2
        clazz.all.should include(a, b)
        clazz.all.count.should == 2
      end

      it "can add a sum after the nodes has been created" do
        clazz = create_node_mixin do
          include Neo4j::Migrations::NodeMixin
          rule :all
        end
        # create nodes with out counter
        a = clazz.new :name =>'a', :age => 4
        b = clazz.new :name =>'b', :age => 3
        finish_tx

        rule_node_props = Neo4j::Rule::Rule.rule_node_for(clazz).rule_node.props
        rule_node_props.should_not include(:sum)
        rule_node_props['_sum_all_age'].should be_nil

        clazz.instance_eval do
          rule(:all, :functions => Neo4j::Rule::Functions::Sum.new(:age))
        end

        clazz.migration 1, :add_all_rule do
          up do
            func = clazz.add_function_for(:all, Neo4j::Rule::Functions::Sum, :age)
            clazz.all.each do |node|
              func.call(node)
            end
          end
        end
        clazz.migrate!
        rule_node_props = Neo4j::Rule::Rule.rule_node_for(clazz).rule_node.props
        #"_#{function_name}_#{rule_name}_#{prop}"
        rule_node_props['_sum_all_age'].should == 7
        clazz.all.sum(:age).should == 7
      end

    end
  end

  context "one migration with an index" do

    context Neo4j::Rails::Model do
      class RailsMigrationTestModel < Neo4j::Rails::Model
        include Neo4j::Migrations::NodeMixin
      end

      it "upgrade migration with added index should make all nodes be found with that index" do
        clazz = RailsMigrationTestModel

        # add none indexed node
        foo   = clazz.create :name => 'foo'

        # make sure this can't be found
        clazz.find(:name => 'foo').should be_nil

        # now add an index on the class
        clazz.index :name

        clazz.migration 1, :add_index do
          add_index :name
        end

        # run the migrations
        clazz.migrate!

        # now we can find the node
        clazz.find(:name => 'foo').should == foo

        clazz.db_version.should == 1
      end
    end

    context Neo4j::NodeMixin, :type => :transactional do
      it "upgrade migration with added index should make all nodes be found with that index" do
        clazz = create_node_mixin do
          rule :all
        end

        # add none indexed node
        foo   = clazz.new :name => 'foo'
        finish_tx

        # make sure this can't be found
        clazz.find(:name => 'foo').should be_empty

        # now add an index on the class
        clazz.index :name

        # add add an migration
        clazz.send(:include, Neo4j::Migrations::NodeMixin)

        clazz.migration 1, :add_index do
          add_index :name
        end

        # run the migrations
        clazz.migrate!

        # now we can find the node
        clazz.find(:name => 'foo').first.should == foo
      end

      it "sets the class #db_version property when a migration has been executed" do
        clazz = create_node_mixin do
          include Neo4j::Migrations::NodeMixin
        end

        finish_tx
        
        clazz.migration 1, :foo do
          up { }
          down { }
        end

        clazz.migrate!

        clazz.db_version.should == 1
      end

      it "downgrade migration with added index should make all nodes NOT be found with that index" do
        clazz = create_node_mixin do
          rule :all
          index :name
        end

        # add none indexed node
        foo   = clazz.new :name => 'foo'
        finish_tx

        clazz.find(:name => 'foo').first.should == foo

        # add a migration
        clazz.send(:include, Neo4j::Migrations::NodeMixin)
        clazz.migration 1, :add_index do
          add_index :name
        end

        # set the migration version to 1 so that we can downgrade to 0
        clazz.db_version = 1

        # run the migrations
        clazz.all.to_a.size.should == 1
        clazz.migrate!(0)

        # now we can find the node
        clazz.find(:name => 'foo').should be_empty
      end

      it "upgrade migration with removed index should make nodes NOT to be found with the removed index" do
        clazz = create_node_mixin do
          rule :all
          index :name
        end

        # add none indexed node
        foo   = clazz.new :name => 'foo'
        finish_tx

        # make sure this can be found
        clazz.find(:name => 'foo').first.should == foo

        # add add an migration
        clazz.send(:include, Neo4j::Migrations::NodeMixin)

        clazz.migration 1, :remove_name_index do
          rm_index :name
        end

        # run the migrations
        clazz.migrate!

        # now we can't' find the node
        clazz.find(:name => 'foo').should be_empty
      end

      it "downgrade migration with removed index should make all nodes be found again with that index" do
        clazz = create_node_mixin do
          rule :all
        end

        # add none indexed node
        foo   = clazz.new :name => 'foo'
        finish_tx
        clazz.find(:name => 'foo').should be_empty

        # add a migration
        clazz.send(:include, Neo4j::Migrations::NodeMixin)
        clazz.migration 1, :remove_this_index do
          rm_index :name
        end

        # since we are downgrading and want to add this index again we have to do it in the source code as well
        clazz.index :name

        # set the migration version to 1 so that we can downgrade to 0
        clazz.db_version = 1

        # run the migrations
        clazz.migrate!(0)

        # now we can find the node
        clazz.find(:name => 'foo').first.should == foo
      end

    end
  end

  context Neo4j::Rails::Model do

    class PersonMigModel < Neo4j::Rails::Model
      include Neo4j::Migrations::NodeMixin
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


  context Neo4j::NodeMixin, :type => :transactional do
    class PersonInfo
      include Neo4j::NodeMixin
      include Neo4j::Migrations::NodeMixin
      rule :all
      property :name
    end

    before(:each) do
      PersonInfo.reset_migrations!
    end

    it "migrate! runs all the migrations" do
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


