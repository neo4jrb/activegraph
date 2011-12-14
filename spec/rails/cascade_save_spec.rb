require File.join(File.dirname(__FILE__), '..', 'spec_helper')


describe "Neo4j::Rails cascade update of models inside callbacks" do

  describe "example model" do
    let!(:person) do
      create_model
    end
    let!(:group) do
      create_model do
        has_n(:people)
      end
    end
    let!(:company) do
      create_model do
        has_n(:groups)
        has_one(:leader)
        def people
          groups.map{|g| g.people}.flatten
        end
      end
    end


    let(:brin) { person.create }
    let(:larry) { person.new }
    let(:google) { company.new(google_data) }

    subject { google }

    context "with modifying code in before_validation" do
      before do
        group_class = group
        company.before_validation do
          g = self.groups.first
          self.groups << (g = group_class.new) unless g
          g.people << leader if !g.people.include?(leader) && leader
        end
      end

      context "when saving" do
        subject { google.save; google.reload }

        context "with leader passed in" do
          let(:google_data) { {:leader => brin} }
          its(:valid?) { should be_true }
          its(:people) { should include brin }
        end

        context "with validation on a leader :)" do
          before { company.validates(:leader, :presence=>true) }
          let(:google_data) { {:leader => nil} }
          its(:valid?) { should be_false }
          its(:people) { should be_empty }

          context "and validating before saving" do
            before { google.valid? }
            let(:google_data) { {:leader => brin} }
            its(:persisted?) { should be_true }
          end

          context "when saving root with persisted nested" do
            let(:google_data) { nil }
            before do
              brin.save!
              google.leader = brin
              google.save!
            end
            its(:persisted?) { should be_true }
            its(:leader) { should == brin }
          end

          context "when saving twice" do
            it "should allow calling `save` twice" do
              him = person.new
              amazon = company.new
              amazon.save.should be_false
              amazon.leader = him
              amazon.save.should be_true
            end
          end
        end
      end

    end
  end
end
