require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neo4j::Rails::Observer do
  let(:recorder) do
    CallbackRecorder.instance
  end

  after do
    recorder.reset
  end

  it "is an instance of an active model observer" do
    AnimalObserver.instance.should be_a_kind_of(ActiveModel::Observer)
  end

  context "when the observer has descendants" do

    let!(:observer) do
      AnimalObserver.instance
    end

    let(:animal) do
      Animal.create!(:name => "Jimmy")
    end

    let(:human) do
      Human.create!(:name => "Cartman")
    end

    it "observes descendent class" do
      animal and observer.last_after_create_record.try(:name).should == animal.name
      human and observer.last_after_create_record.try(:name).should == human.name
    end
  end

  it "should be enabled by default" do
    AnimalObserver.instance.should be_observer_enabled
  end

  context "when all the observers are disabled" do
    before { Neo4j::Rails::Observer.disable_observers }
    after  { Neo4j::Rails::Observer.enable_observers  }

    it "should not run" do
      Human.new(:name => 'Dmytrii').valid?
      Animal.new(:name => 'Tuzik').valid?
      recorder.call_count.should be_empty
    end

    it "should run a temporarily enabled one" do
      Neo4j::Rails::Observer.with_observers(:callback_recorder) do
        Animal.new.valid?
      end
      recorder.call_count.should_not be_empty
    end
  end

  context "when the node is new" do

    let!(:animal) do
      Animal.new
    end

    it "observes after initialize" do
      recorder.last_callback.should == :after_initialize
    end

    it "calls after initialize once" do
      recorder.call_count[:after_initialize].should == 1
    end

    it "contains the model of the callback" do
      recorder.last_record[:after_initialize].should eq(animal)
    end
  end

  context "when the node is being created" do

    let!(:animal) do
      Animal.create!
    end

    [ :before_create,
      :after_create,
      :around_create,
      :before_save,
      :after_save,
      :around_save ].each do |callback|

      it "observes #{callback}" do
        recorder.call_count[callback].should == 1
      end

      it "contains the model of the callback" do
        recorder.last_record[callback].should eq(animal)
      end
    end
  end

  context "when the node is being updated" do

    let!(:animal) do
      Animal.create!
    end

    [ :before_update,
      :after_update,
      :around_update,
      :before_save,
      :after_save,
      :around_save ].each do |callback|

      before do
        recorder.reset
        animal.update_attributes!(:name => "Johnny Depp")
      end

      it "observes #{callback}" do
        recorder.call_count[callback].should == 1
      end

      it "contains the model of the callback" do
        recorder.last_record[callback].should eq(animal)
      end
    end
  end

  context "when the node is being destroyed" do

    let!(:animal) do
      Animal.create!
    end

    [ :before_destroy, :after_destroy, :around_destroy ].each do |callback|

      before do
        recorder.reset
        animal.destroy
      end

      it "observes #{callback}" do
        recorder.call_count[callback].should == 1
      end

      it "contains the model of the callback" do
        recorder.last_record[callback].should eq(animal)
      end
    end
  end

  context "when the node is being validated" do

    let!(:animal) do
      Animal.new
    end

    [:before_validation, :after_validation].each do |callback|

      before do
        recorder.reset
        animal.valid?
      end

      it "observes #{callback}" do
        recorder.call_count[callback].should == 1
      end

      it "contains the model of the callback" do
        recorder.last_record[callback].should eq(animal)
      end
    end
  end
end
