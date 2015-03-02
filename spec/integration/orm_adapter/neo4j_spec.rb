require 'spec_helper'

orm_adapter_path = `bundle show orm_adapter`.chomp
require File.join(orm_adapter_path, 'spec/orm_adapter/example_app_shared')

module Neo4j
  module OrmSpec
    describe '[Neo4j orm adapter]', type: :integration do
      before :each do
        delete_db
      end

      #      describe "the OrmAdapter class" do
      #        subject { Neo4j::ActiveNode::OrmAdapter }
      #
      #        specify "#model_classes should return all of the model classes (that are not in except_classes)" do
      #          subject.model_classes.should include(User, Note)
      #        end
      #      end

      it_should_behave_like 'example app with orm_adapter fix' do
        before(:each) do
          Neo4j::ActiveNode::Labels.clear_model_for_label_cache
          Neo4j::ActiveNode::Labels.clear_wrapped_models

          stub_active_node_class('User') do
            property :name, index: :exact
            property :rating, type: Integer, index: :exact

            index :name

            has_many :out, :notes, model_class: 'Note'
          end
          #require 'pry'
          #binding.pry

          stub_active_node_class('Note') do
            property :body, index: :exact

            has_one :in, :owner, type: :notes, model_class: 'User'
          end
        end

        #let(:user_class) { require 'pry'; binding.pry; User }
        let(:user_class) { User }
        let(:note_class) { Note }
      end
    end
  end
end
