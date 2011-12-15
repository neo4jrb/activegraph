require File.join(File.dirname(__FILE__), '..', 'spec_helper')


class FormtasticAssociatedModel < Neo4j::Model
  property :name
end

class FormtasticModel < Neo4j::Model
  property :name
  has_n(:children).to(FormtasticAssociatedModel)
end

describe Neo4j::Rails::Model, "has_n" do

  subject do
    FormtasticModel.new
  end


  context "when assign with an array of strings" do

    before do
      @a = FormtasticAssociatedModel.create(:name => 'a')
      @b = FormtasticAssociatedModel.create(:name => 'b')
      @c = FormtasticAssociatedModel.create(:name => 'c')
      @d = FormtasticAssociatedModel.create(:name => 'd')
    end


    context "when no relationships exists" do
      context "when array contains two String integers and first item is an empty string" do
        before do
          subject.children = ["", @a.id, @b.id]
        end
        it "should create new relationships" do
          subject.children.should include(@a, @b)
          subject.children.size.should == 2
        end

        it "should persisted the new relationship" do
          subject.save!
          subject.children.should include(@a, @b)
          subject.children.size.should == 2
        end

      end

      context "when array is two String integers" do
        before do
          subject.children = [@a.id, @b.id]
        end
        it "should create new relationships" do
          subject.children.should include(@a, @b)
          subject.children.size.should == 2
        end

        it "should persisted the new relationship" do
          subject.save!
          subject.children.should include(@a, @b)
          subject.children.size.should == 2
        end
      end

    end

    context "when relationships exists" do

      context "when array contains two String integers which already exists" do
        before do
          subject.children << @c << @d
          subject.save!
          subject.children = [@a.id, @d.id]
        end

        it "should not add the same node twice" do
          subject.children.should include(@a, @c, @d)
          subject.children_rels.size.should == 3
          subject.save!
          subject.reload
          subject.children.should include(@a, @c, @d)
          subject.children_rels.size.should == 3

        end
      end

      context "when array contains two String integers and first item is an empty string" do
        before do
          subject.children << @c << @d
          subject.save!
          subject.children = ["", @a.id, @b.id]
        end

        it "should create two new relationships" do
          subject.children.should include(@a, @b)
        end

        it "should persist the two new relationships" do
          subject.save!
          subject.reload
          subject.children.should include(@a, @b)
        end

        it "should keep the old relationship" do
          subject.children.should_not include(@c, @d)
          subject.children.size.should == 2
        end
      end

      context "when array is two String integers" do
        before do
          subject.children << @c << @d
          subject.save!
          subject.children = [@a.id, @b.id]
        end

        it "should create two new relationships" do
          subject.children.should include(@a, @b)
        end

        it "should persist the two new relationships" do
          subject.save!
          subject.reload
          subject.children.should include(@a, @b)
        end

        it "should keep the old relationship" do
          subject.children.should include(@c, @d)
          subject.children.size.should == 4
        end

        it "should keep the old relationship after save" do
          subject.save!
          subject.reload
          subject.children.should include(@c, @d)
          subject.children.size.should == 4
        end

        it "should persisted the new relationship" do
          subject.save!
          subject.children.should include(@a, @b, @c, @d)
        end
      end
    end

  end

end
