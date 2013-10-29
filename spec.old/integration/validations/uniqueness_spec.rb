require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

module Neo4j
  module Rails
    module Validations

      describe "Validations" do


        let(:uniqueness_class) do
          create_model do
            property :name, :index => :exact
            validates :name, :presence => true, :uniqueness => true
          end
        end

        let(:inherited_uniqueness_class) do
          create_model(uniqueness_class)
        end

        let(:allow_blank_class) do
          create_model do
            property :name, :title, :index => :exact
            validates :name, :uniqueness => true, :allow_blank => true
            validates :title, :uniqueness => true, :allow_blank => false
          end
        end

        describe "get_or_create" do
          let(:get_or_create_class) do
            create_model do
              property :email, :index => :exact, :unique => true
              property :name
            end
          end

          subject do
            get_or_create_class
          end

          it "if it does not exist it should create a new" do
            node = get_or_create_class.get_or_create(:name => 'foo', :email => 'email')
            node[:name].should == 'foo'
            node[:email].should == 'email'
          end

          it "returns old if it already exists" do
            old = get_or_create_class.get_or_create(:name => 'abc', :email => 'email@old.se')
            new = get_or_create_class.get_or_create(:name => 'def', :email => 'email@old.se')
            new._java_node.should == old._java_node
            new[:name].should == 'abc'
            new[:email].should == 'email@old.se'
          end

        end

        describe "UniquenessTest" do
          subject { uniqueness_class.new }

          before(:each) do
            subject.class.create(:name => "test 1")
            subject.class.create(:name => "test 2")
          end

          context "when invalid" do
            before(:each) do
              subject.name = "test 1"
            end

            it_should_behave_like "a new model"
            it_should_behave_like "an unsaveable model"
            it_should_behave_like "an uncreatable model"
            it_should_behave_like "a non-updatable model"

            it "should have errors on the property" do
              subject.should_not be_valid
              subject.errors[:name].should_not be_empty
            end

            it "should have the right translation" do
              subject.valid?
              subject.errors[:name].should include("has already been taken")
            end
          end

          context "when valid" do
            before(:each) { subject.name = "test" }

            it_should_behave_like "a new model"
            it_should_behave_like "a loadable model"
            it_should_behave_like "a saveable model"
            it_should_behave_like "a creatable model"
            it_should_behave_like "a destroyable model"
            it_should_behave_like "an updatable model"

            context "after save" do
              before(:each) do
                subject.save
                subject.reload
              end

              it { should be_valid }
            end
          end
        end

        describe "InheritedUniquenessTest" do
          subject { inherited_uniqueness_class.new }

          before(:each) do
            subject.class.create(:name => "test 1")
            subject.class.create(:name => "test 2")
          end

          context "when invalid" do
            before(:each) do
              subject.name = "test 1"
            end

            it_should_behave_like "a new model"
            it_should_behave_like "an unsaveable model"
            it_should_behave_like "an uncreatable model"
            it_should_behave_like "a non-updatable model"
            it "should have errors on the property" do
              subject.should_not be_valid
              subject.errors[:name].should_not be_empty
            end
          end

          context "when valid" do
            before(:each) { subject.name = "test" }

            it_should_behave_like "a new model"
            it_should_behave_like "a loadable model"
            it_should_behave_like "a saveable model"
            it_should_behave_like "a creatable model"
            it_should_behave_like "a destroyable model"
            it_should_behave_like "an updatable model"

            context "after save" do
              before(:each) do
                subject.save
                subject.reload
              end

              it { should be_valid }
            end
          end
        end

        describe "AllowBlankTest" do
          subject { allow_blank_class.new }

          before(:each) do
            subject.class.create!(:name => "Test", :title => "Test")
            subject.class.create!(:name => "", :title => "")
          end

          it "should be valid if name and title are unique" do
            subject.name = "Different"
            subject.title = "Different"
            subject.should be_valid
          end

          it "shouldn't be valid if title is blank" do
            subject.name = "Different"
            subject.title = ""
            subject.should_not be_valid
          end

          it "should be valid if name is blank" do
            subject.name = ""
            subject.title = "Different"
            subject.should be_valid
          end
        end

        describe "An unindexed unique field" do
          it "should cause an exception for case sensitive matches" do
            expect do
              class UnindexedTest < Neo4j::Rails::Model
                property :name

                validates :name, :uniqueness => true
              end
            end.to raise_error(StandardError, "Can't validate property :name on class Neo4j::Rails::Validations::UnindexedTest" +
                " since there is no :exact lucene index on that property or the index declaration name comes after the validation" +
                " declaration in Neo4j::Rails::Validations::UnindexedTest (try to move it before the validation rules)")
          end

          it "should cause an exception for case insensitive matches" do
            expect do
              class CaseInsensitiveUnindexedTest < Neo4j::Rails::Model
                property :name

                validates :name, :uniqueness => {:case_sensitive => false}
              end
            end.to raise_error(StandardError, "Can't validate property :name on class Neo4j::Rails::Validations::CaseInsensitiveUnindexedTest" +
                " since there is no :fulltext lucene index on that property or the index declaration name comes after the validation" +
                " declaration in Neo4j::Rails::Validations::CaseInsensitiveUnindexedTest (try to move it before the validation rules)")
          end
        end

        describe "Case sensitivity" do
          it "should check uniqueness on case sensitive basis by default" do
            class CaseSensitiveTest < Neo4j::Rails::Model
              property :name
              index :name
              validates :name, :uniqueness => true
            end
            CaseSensitiveTest.create :name => "Valid"
            duplicate = CaseSensitiveTest.new :name => "Valid"
            duplicate.valid?
            duplicate.errors[:name].should include("has already been taken")
            lower_case = CaseSensitiveTest.new :name => "valid"
            lower_case.should be_valid
          end

          it "should check properties on a case insensitive basis if specified" do
            class CaseInsensitiveTest < Neo4j::Rails::Model
              property :name
              index :name, :type => :fulltext
              validates :name, :uniqueness => {:case_sensitive => false}
            end
            CaseInsensitiveTest.create :name => "Valid"
            duplicate_with_lower_case = CaseInsensitiveTest.new :name => "valid"
            duplicate_with_lower_case.valid?
            duplicate_with_lower_case.errors[:name].should include("has already been taken")
          end

          it "should check properties with spaces for case insensitive propeties" do
            class CaseInsensitiveWithSpacesTest < Neo4j::Rails::Model
              property :name
              index :name, :type => :fulltext
              validates :name, :uniqueness => {:case_sensitive => false}
            end
            CaseInsensitiveWithSpacesTest.create :name => "Valid Space"
            duplicate_with_lower_case = CaseInsensitiveWithSpacesTest.new :name => "valid space"
            duplicate_with_lower_case.valid?
            duplicate_with_lower_case.errors[:name].should include("has already been taken")
            ["valid", "space"].each do |text|
              other = CaseInsensitiveWithSpacesTest.new :name => text
              other.should be_valid
            end
          end

          it "should allow presence validation with case insensitive propeties" do
            class CaseInsensitiveWithNilTest < Neo4j::Rails::Model
              property :name, :required
              index :name, :type => :fulltext
              validates :name, :uniqueness => {:case_sensitive => false}
              validates :required, :presence => true
            end
            CaseInsensitiveWithNilTest.new.should be_invalid
            #CaseInsensitiveWithNilTest.new.should validate_presence_of :required
          end

          it "should check properties on a case insensitive basis with allow_blank false" do
            class CaseInsensitiveWithAllowBlankFalseTest < Neo4j::Rails::Model
              property :name
              index :name, :type => :fulltext
              validates :name, :uniqueness => {:case_sensitive => false}, :allow_blank => false
            end
            CaseInsensitiveWithAllowBlankFalseTest.create :name => ""
            duplicate = CaseInsensitiveWithAllowBlankFalseTest.new :name => ""
            duplicate.should be_invalid
            duplicate.errors[:name].should include("has already been taken")
          end

          it "should handle quotes in unique properties" do
            class CaseInsensitiveWithQuotesTest < Neo4j::Rails::Model
              property :name
              index :name, :type => :fulltext
              validates :name, :uniqueness => {:case_sensitive => false}
            end
            CaseInsensitiveWithQuotesTest.create :name => "test\"\""
            duplicate = CaseInsensitiveWithQuotesTest.new :name => "test\"\""
            duplicate.should be_invalid
            duplicate.errors[:name].should include("has already been taken")
          end
        end
      end
    end
  end
end