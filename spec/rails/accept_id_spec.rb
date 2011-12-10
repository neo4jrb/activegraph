require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class AcceptIdAssociatedModel < Neo4j::Model
end
class GenericIdTestModel < Neo4j::Model
end
class AcceptIdModel < Neo4j::Model
  has_one(:child).to(AcceptIdAssociatedModel)
  has_one(:generic_child)
  has_one(:other_child)
  accepts_id_for :child, :generic_child
end

describe Neo4j::Rails::AcceptId do
  describe "accepts_id_for" do
    it "should generate a getter" do
      AcceptIdModel.new.should respond_to(:child_id)
    end

    it "should generate a setter" do
      AcceptIdModel.new.should respond_to(:child_id=)
    end
  end

  describe "accepts_id_for?" do
    it "should be true for child for which ids are accepted" do
      AcceptIdModel.accepts_id_for?(:child).should be_true
    end

    it "should be false for child for which ids are not accepted" do
      AcceptIdModel.accepts_id_for?(:other_child).should be_false
    end
  end

  describe "generated getter(child_id)" do
    context "when child is set" do
      it "should be id of the child" do
        child = AcceptIdAssociatedModel.create!
        parent = AcceptIdModel.create!(:child => child)
        parent.child_id.should == child.id
      end
    end

    context "when child is not set" do
      it "should be nil" do
        parent = AcceptIdModel.create!
        parent.child_id.should be_nil
      end
    end
  end

  describe "generated setter(child_id=)" do
    context "when child id is given" do
      context "when child exists" do
        it "should set the child" do
          child = AcceptIdAssociatedModel.create!
          parent = AcceptIdModel.create!

          parent.child_id = child.id

          parent.child.should == child
        end
      end

      context "when child does not exist" do
        it "should set the child" do
          pending "Need to figure out how to validate non existing child"
          parent = AcceptIdModel.create!

          parent.child_id = 'non.existing.child.id'
          parent.save

          parent.should_not be_persisted
          parent.errors[:child_id].should include("AcceptIdAssociatedModel by id = non.existing.child.id not found")
        end
      end

      context "when same child is assigned twice" do
        it "should not create duplicate relations between nodes" do
          child = AcceptIdAssociatedModel.create!
          parent = AcceptIdModel.create!(:child => child)

          parent.reload
          parent.update_attributes!(:child_id => child.id)

          parent.reload.child.should == child
        end
      end
    end

    context "when association does not have target class" do
      it "should set the child as instance of found neo4j model" do
        generic_child = GenericIdTestModel.create!
        parent = AcceptIdModel.create!

        parent.generic_child_id = generic_child.id

        parent.generic_child_id.should == generic_child.id
      end
    end

    context "when child_id is nil" do
      it "should set the child to nil" do
        parent = AcceptIdModel.create!(:child => AcceptIdAssociatedModel.create!)

        parent.child_id = nil

        parent.child.should be_nil
      end
    end
  end
end
