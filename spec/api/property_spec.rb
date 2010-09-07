$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require 'spec_helper'

describe Neo4j::Property do
  def setup_graph_db
    graph_db = double("EmbeddedGraphDatabase")
    db = double("Database")
    db.should_receive(:graph).any_number_of_times.and_return(graph_db)
    Neo4j.stub!(:db).and_return(db)
    graph_db
  end

  instance_methods do
    send(:[], arg(:key)) do
      Scenario 'returns the property if it exists' do
        Given do
          arg.key = 'foo'
          subject.stub!(:has_property?).and_return(true)
          subject.stub!(:get_property).and_return('bar')
        end
        Return do
          it ("the property value") { should == 'bar' }
        end
      end

      Scenario 'returns nil if property does not exist' do
        Given do
          arg.key = 'foo'
          subject.stub!(:has_property?).and_return(false)
        end
        Return do
          it ("the property value") { should be_nil }
        end
      end
    end

    send(:[]=, arg(:key), arg(:value)) do
      Scenario 'sets property when value is not nil' do
        Given do
          arg.key = :foo
          arg.value = "some value"
          subject.stub!(:set_property).with('foo', 'some value')
        end
        Return do
          it ("nil") { should == nil }
        end
      end

      Scenario 'deletes property when value is nil' do
        Given do
          arg.key = :baaz
          arg.value = nil
          subject.stub!(:remove_property).with('baaz')
        end
        Return do
          it ("nil") { should == nil }
        end
      end

    end

  end

end

