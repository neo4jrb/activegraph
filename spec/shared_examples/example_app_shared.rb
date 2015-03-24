# Copied from orm_adapter and fixed some Specs

# to test your new orm_adapter, make an example app that matches the functionality
# found in the existing specs for example, look at spec/orm_adapter/adapters/active_record_spec.rb
#
# Then you can execute this shared spec as follows:
#
#   it_should_behave_like "execute app with orm_adapter" do
#     let(:user_class) { User }
#     let(:note_class) { Note }
#
#     # optionaly define the following functions if the ORM does not support
#     # this syntax - this should NOT use the orm_adapter, because we're testing that
#     def create_model(klass, attrs = {})
#       klass.create!(attrs)
#     end
#
#     def reload_model(model)
#       model.class.find(model.id)
#     end
#   end
#
shared_examples_for 'example app with orm_adapter fix' do
  def create_model(klass, attrs = {})
    klass.create!(attrs)
  end

  def reload_model(model)
    model.class.find(model.id)
  end

  describe 'an ORM class' do
    subject { note_class }
    let(:adapter) { subject.to_adapter }

    it '#to_adapter should return an adapter instance' do
      adapter.should be_a(OrmAdapter::Base)
    end

    it '#to_adapter should return an adapter for the receiver' do
      adapter.klass.should eq(subject)
    end

    it '#to_adapter should be cached' do
      adapter.object_id.should eq(adapter.object_id)
    end
  end

  describe 'adapter instance' do
    let(:note_adapter) { note_class.to_adapter }
    let(:user_adapter) { user_class.to_adapter }

    describe '#get!(id)' do
      it 'should return the instance with id if it exists' do
        user = create_model(user_class)
        user_adapter.get!(user.id).should eq(user)
      end

      it 'should allow to_key like arguments' do
        user = create_model(user_class)
        user_adapter.get!(user.to_key).should eq(user)
      end

      it 'should raise an error if there is no instance with that id' do
        lambda { user_adapter.get!('nonexistent id') }.should raise_error
      end
    end

    describe '#get(id)' do
      it 'should return the instance with id if it exists' do
        user = create_model(user_class)
        user_adapter.get(user.id).should eq(user)
      end

      it 'should allow to_key like arguments' do
        user = create_model(user_class)
        user_adapter.get(user.to_key).should eq(user)
      end

      it 'should return nil if there is no instance with that id' do
        user_adapter.get('nonexistent id').should be_nil
      end
    end

    describe '#find_first' do
      describe '(conditions)' do
        it 'should return first model matching conditions, if it exists' do
          user = create_model(user_class, name: 'Fred')
          user_adapter.find_first(name: 'Fred').should eq(user)
        end

        it 'should return nil if no conditions match' do
          user_adapter.find_first(name: 'Betty').should.nil?
        end

        it 'should return the first model if no conditions passed' do
          user = create_model(user_class)
          create_model(user_class)
          user_adapter.find_first.neo_id.should eq(user.neo_id)
        end

        it 'when conditions contain associated object, should return first model if it exists' do
          user = create_model(user_class)
          note = create_model(note_class, owner: user)
          note_adapter.find_first(owner: user).should eq(note)
        end

        it 'understands :id as a primary key condition (allowing scoped finding)' do
          create_model(user_class, name: 'Fred')
          user = create_model(user_class, name: 'Fred')
          user_adapter.find_first(id: user.id, name: 'Fred').should eq(user)
          user_adapter.find_first(id: user.id, name: 'Not Fred').should be_nil
        end
      end

      describe '(:order => <order array>)' do
        it 'should return first model in specified order' do
          create_model(user_class, name: 'Fred', rating: 1)
          user = create_model(user_class, name: 'Fred', rating: 2)

          user_adapter.find_first(order: [:name, [:rating, :desc]]).should eq(user)
        end
      end

      describe '(:conditions => <conditions hash>, :order => <order array>)' do
        it 'should return first model matching conditions, in specified order' do
          create_model(user_class, name: 'Fred', rating: 1)
          user = create_model(user_class, name: 'Fred', rating: 2)

          user_adapter.find_first(conditions: {name: 'Fred'}, order: [:rating, :desc]).should eq(user)
        end
      end
    end

    describe '#find_all' do
      describe '(conditions)' do
        it 'should return only models matching conditions' do
          user1 = create_model(user_class, name: 'Fred')
          user2 = create_model(user_class, name: 'Fred')
          create_model(user_class, name: 'Betty')

          user_adapter.find_all(name: 'Fred').to_a.should =~ [user1, user2]
        end

        it 'should return all models if no conditions passed' do
          user1 = create_model(user_class, name: 'Fred')
          user2 = create_model(user_class, name: 'Fred')
          user3 = create_model(user_class, name: 'Betty')
          user_adapter.find_all.to_a.should =~ [user1, user2, user3]
        end

        it 'should return empty array if no conditions match' do
          user_adapter.find_all(name: 'Fred').should eq([])
        end

        it 'when conditions contain associated object, should return first model if it exists' do
          user1, user2 = create_model(user_class), create_model(user_class)
          create_model(note_class, owner: user1)

          note = create_model(note_class, owner: user2)
          note_adapter.find_all(owner: user2).should eq([note])
        end
      end

      describe '(:order => <order array>)' do
        it 'should return all models in specified order' do
          user1 = create_model(user_class, name: 'Fred', rating: 1)
          user2 = create_model(user_class, name: 'Fred', rating: 2)
          user3 = create_model(user_class, name: 'Betty', rating: 1)
          user_adapter.find_all(order: [:name, [:rating, :desc]]).should eq([user3, user2, user1])
        end
      end

      describe '(:conditions => <conditions hash>, :order => <order array>)' do
        it 'should return only models matching conditions, in specified order' do
          user1 = create_model(user_class, name: 'Fred', rating: 1)
          user2 = create_model(user_class, name: 'Fred', rating: 2)
          create_model(user_class, name: 'Betty', rating: 1)

          user_adapter.find_all(conditions: {name: 'Fred'}, order: [:rating, :desc]).should eq([user2, user1])
        end
      end

      describe '(:limit => <number of items>)' do
        it 'should return a limited set of matching models' do
          user1 = create_model(user_class, name: 'Fred', rating: 1)
          user2 = create_model(user_class, name: 'Fred', rating: 2)
          create_model(user_class, name: 'Betty', rating: 3)

          user_adapter.find_all(limit: 1, order: [:rating, :asc]).should eq([user1])
          user_adapter.find_all(limit: 2, order: [:rating, :asc]).should eq([user1, user2])
        end
      end

      describe "(:offset => <offset number>) with limit (as DataMapper doesn't allow offset on its own)" do
        it 'should return an offset set of matching models' do
          user1 = create_model(user_class, name: 'Fred', rating: 1)
          user2 = create_model(user_class, name: 'Fred', rating: 2)
          user3 = create_model(user_class, name: 'Betty', rating: 3)
          user_adapter.find_all(limit: 3, offset: 0, order: [:rating, :asc]).should eq([user1, user2, user3])
          user_adapter.find_all(limit: 3, offset: 1, order: [:rating, :asc]).should eq([user2, user3])
          user_adapter.find_all(limit: 1, offset: 1, order: [:rating, :asc]).should eq([user2])
        end
      end
    end

    describe '#create!(attributes)' do
      it 'should create a model with the passed attributes' do
        user = user_adapter.create!(name: 'Fred')
        reload_model(user).name.should eq('Fred')
      end

      it 'should raise error when create fails' do
        lambda { user_adapter.create!(user: create_model(note_class)) }.should raise_error
      end

      it 'when attributes contain an associated object, should create a model with the attributes' do
        user = create_model(user_class)
        note = note_adapter.create!(owner: user)
        reload_model(note).owner.should eq(user)
      end

      it 'when attributes contain an has_many assoc, should create a model with the attributes' do
        notes = [create_model(note_class), create_model(note_class)]
        user = user_adapter.create!(notes: notes)
        expect(reload_model(user).notes.sort_by(&:neo_id)).to eq(notes.sort_by(&:neo_id))
      end
    end

    describe '#destroy(instance)' do
      it 'should destroy the instance if it exists' do
        skip 'This does not work on Neo4j Embedded DB, since IDs can be reused see GraphDatabaseService#getNodeById, http://docs.neo4j.org/chunked/2.1.1/javadocs/'
        user = create_model(user_class)
        (!!user_adapter.destroy(user)).should eq(true)  # make it work with both RSpec 2.x and 3.x
        user_adapter.get(user.id).should be_nil
      end

      it 'should return nil if passed with an invalid instance' do
        user_adapter.destroy('nonexistent instance').should be_nil
      end

      it "should not destroy the instance if it doesn't match the model class" do
        skip 'This does not work on Neo4j Embedded DB, since IDs can be reused see GraphDatabaseService#getNodeById, http://docs.neo4j.org/chunked/2.1.1/javadocs/'
        user = create_model(user_class)
        note_adapter.destroy(user).should be_nil
        user_adapter.get(user.id).should eq(user)
      end
    end
  end
end
