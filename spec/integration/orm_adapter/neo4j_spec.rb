orm_adapter_path = `bundle show orm_adapter`.chomp
require File.join(orm_adapter_path, 'spec/orm_adapter/example_app_shared')

module ActiveGraph
  module OrmSpec
    describe '[Neo4j orm adapter]', type: :integration do
      #      describe "the OrmAdapter class" do
      #        subject { ActiveGraph::ActiveNode::OrmAdapter }
      #
      #        specify "#model_classes should return all of the model classes (that are not in except_classes)" do
      #          subject.model_classes.should include(User, Note)
      #        end
      #      end

      it_should_behave_like 'example app with orm_adapter fix' do
        before(:each) do
          clear_model_memory_caches

          create_index :User, :name, type: :exact
          create_index :User, :rating, type: :exact

          stub_active_node_class('User') do
            property :name
            property :rating, type: Integer

            has_many :out, :notes, type: nil, model_class: 'Note'
          end

          create_index :Note, :body, type: :exact
          stub_active_node_class('Note') do
            property :body

            has_one :in, :owner, type: :notes, model_class: 'User'
          end
        end

        let(:user_class) { User }
        let(:note_class) { Note }
      end
    end
  end
end
