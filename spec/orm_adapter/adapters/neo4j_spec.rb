require 'spec_helper'
require 'orm_adapter/example_app_shared'

module Neo4j
	module OrmSpec
		class Note < Neo4j::Rails::Model
		end
		
		class User < Neo4j::Rails::Model
			index 		:name
			property 	:name
			
			has_n(:notes).to(Note)
		end
	
		class Note < Neo4j::Rails::Model
			index			:body
			property 	:body
			
			has_one(:owner).from(User, :notes)
		end
	
		# here be the specs!
		describe '[Neo4j orm adapter]', :type => :integration do
			describe "the OrmAdapter class" do
				subject { Neo4j::Rails::Model::OrmAdapter }
	
				specify "#model_classes should return all of the model classes (that are not in except_classes)" do
					subject.model_classes.should include(User, Note)
				end
			end
		
			it_should_behave_like "example app with orm_adapter" do
				let(:user_class) { User }
				let(:note_class) { Note }
			end
		end
	end
end