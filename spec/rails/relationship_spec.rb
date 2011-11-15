require File.join(File.dirname(__FILE__), '..', 'spec_helper')


class RelationshipWithNoProperty < Neo4j::Rails::Relationship
end

class NodeWithRelationship < Neo4j::Rails::Model
  has_one(:other_node)
  has_one(:foobar).relationship(RelationshipWithNoProperty)
  has_n(:baaz)

  def to_s
    "node object_id: #{object_id} #{self._java_node ? neo_id : "not persisted"}"
  end
end

describe "Neo4j::Model Relationships" do
  describe "incoming" do
    it "created incoming relationship can be accessed from outgoing node" do
      clazz = create_model
      a = clazz.create
      b = clazz.create

      a.incoming(:foo) << b
      a.save
      # then
      a.incoming(:foo).size.should == 1
      a.incoming(:foo).should include(b)

      b.outgoing(:foo).size.should == 1
      b.outgoing(:foo).to_a.should include(a)

      # reload
      a = clazz.find(a.id)
      b = clazz.find(b.id)

      a.incoming(:foo).size.should == 1
      a.incoming(:foo).should include(b)

      b.outgoing(:foo).size.should == 1
      b.outgoing(:foo).should include(a)
    end
  end

  describe "Neo4j::Model Relationship#rel_type" do
    context "when not persisted" do
      it "returns the type of the relationship" do
        rel = RelationshipWithNoProperty.new(:foo, Neo4j::Rails::Model.create, Neo4j::Rails::Model.create)
        rel.rel_type.should == 'foo'
      end
    end

    context "when persisted" do
      it "returns the type of the relationship" do
        rel = RelationshipWithNoProperty.create!(:foo, Neo4j::Rails::Model.create, Neo4j::Rails::Model.create)
        rel.rel_type.should == 'foo'
      end
    end
  end


  describe "Neo4j::Model#rels" do
    before(:each) do
      @a = Neo4j::Rails::Model.create(:name => 'a')
      @b = Neo4j::Rails::Model.create(:name => 'b')
      @c = Neo4j::Rails::Model.create(:name => 'c')
      @d = Neo4j::Rails::Model.create(:name => 'd')
      @a.outgoing(:foo) << @b << @c
      @a.save!
      Neo4j::Rails::Relationship.create!(:bar, @a, @d, :name => 'ad1')
      Neo4j::Rails::Relationship.create!(:bar, @a, @d, :name => 'ad2')

      # none persisted
      @a1 = Neo4j::Rails::Model.new(:name => 'a1')
      @b1 = Neo4j::Rails::Model.new(:name => 'b1')
      @c1 = Neo4j::Rails::Model.new(:name => 'c1')
      @d1 = Neo4j::Rails::Model.new(:name => 'd1')
      @a1.outgoing(:foo) << @b1 << @c1
      Neo4j::Rails::Relationship.new(:bar, @a1, @d1, :name => 'ad11')
      Neo4j::Rails::Relationship.new(:bar, @a1, @d1, :name => 'ad21')
    end

    context "find all relationships (#rels())" do
      context "when all relationships are persisted" do
        it "returns all relationships if no type is given" do
          @a.rels().size.should == 5
          @a.rels.map { |x| x[:name] }.compact.should =~ %w[ad1 ad2]
        end

        describe "delete all found relationship" do
          it "delete with #del deletes all relationships" do
            @a.rels().size.should > 0
            @a.rels().del # alias for delete_all for consistency with Neo4j::NodeMixin api
            @a.rels().size.should == 0
          end

          it "delete with #destroy deletes all relationships" do
            @a.rels().size.should > 0
            @a.rels().destroy_all
            @a.rels().size.should == 0
          end
        end

        describe "to_other" do
          it "returns an Enumerable of all found relationships between the given nodes" do
            @a.rels.to_other(@d).to_a.size.should == 2
            rels = @a.rels(:bar).to_other(@d).map { |n| n[:name] }
            rels.should =~ ['ad1', 'ad2']
          end

          it "returns nothing if there are no relationship between the given nodes" do
            @a.rels.to_other(Neo4j::Rails::Model.create!).to_a.should == []
          end

          it "accepts a Neo4j::Node as the other node" do
            other_node = Neo4j::Transaction.run{n = Neo4j::Node.new(:name => 'fooo'); @a._java_node.outgoing(:baz) << n; n}
            rel = @a.rels.to_other(other_node).first
            rel.class.should == Neo4j::Relationship
            rel.end_node.should == other_node
          end
        end
      end

      context "when no relationships are persisted" do
        it "returns all relationships if no type is given" do
          @a1.rels().size.should == 4 # the _all relationship to ref node should be missing
          @a1.rels.map { |x| x[:name] }.compact.should =~ %w[ad11 ad21]
        end

        describe "delete all found relationship" do
          it "delete with #delete_all deletes all relationships" do
            @a1.rels().size.should > 0
            @a1.rels().delete_all
            @a1.rels().size.should == 0
          end

          it "delete with #destroy deletes all relationships" do
            @a1.rels().size.should > 0
            @a1.rels().destroy_all
            @a1.rels().size.should == 0
          end
        end
      end
    end

    context "find a specific relationship type (#rels(:rel_type))" do
      context "when all relationships are persisted" do
        it "returns all relationships of the given type" do
          @a.rels(:foo).size.should == 2
          @a.rels(:bar).map { |x| x[:name] }.compact.should =~ %w[ad1 ad2]
        end

        describe "delete all found relationship of a given type" do
          it "deletes with #delete_all" do
            @a.rels(:foo).size.should > 0
            @a.rels(:foo).delete_all
            @a.rels(:foo).size.should == 0
          end

          it "deletes with #destroy_all" do
            @a.rels(:foo).size.should > 0
            @a.rels(:foo).destroy_all
            @a.rels(:foo).size.should == 0
          end
        end

        describe "to_other" do
          it "return an Enumerable of all found relationships between the given nodes" do
            @a.rels(:foo).to_other(@b).size.should == 1
            rels = @a.rels(:bar).to_other(@d).map { |n| n[:name] }
            rels.should =~ ['ad1', 'ad2']
          end

          it "raise an exception if the node is not persisted" do
            lambda { Neo4j::Rails::Model.new.rels(:bar).to_other(Neo4j.ref_node) }.should raise_error
          end
        end
      end

      context "when no relationships are persisted" do
        it "returns all relationships if no type is given" do
          @a1.rels(:foo).size.should == 2
          @a1.rels(:bar).map { |x| x[:name] }.compact.should =~ %w[ad11 ad21]
        end

        describe "delete all relationship of given type" do
          it "delete with #del deletes all relationships" do
            @a1.rels(:foo).size.should > 0
            @a1.rels(:foo).delete_all
            @a1.rels(:foo).size.should == 0
            @a1.rels.size.should > 0
          end

          it "delete with #destroy deletes all relationships" do
            @a1.rels(:foo).size.should > 0
            @a1.rels(:foo).destroy_all
            @a1.rels(:foo).size.should == 0
            @a1.rels.size.should > 0
          end
        end

        describe "to_other" do
          it "raise an exception since it only allows finding persisted relationships" do
            lambda{@a1.rels(:foo).to_other(@b1).to_a}.should raise_error
          end
        end

      end
    end
  end


  describe "has_n from" do
    before(:each) do
      @b_clazz = create_model
      @b_clazz.has_n :friends
      @a_clazz = create_model
      @a_clazz.has_n(:known_by).from(:friends)

      @a = @a_clazz.create
      @b = @b_clazz.create
      @a.known_by << @b
      @a.save
    end

    it "should find the node both ways" do
      @a.known_by.size.should == 1
      @a.known_by.should include(@b)
      @b.friends.size.should == 1
      @b.friends.should include(@a)
    end

    it "when reloaded it can also be found" do
      a = @a_clazz.find(@a.id)
      b = @b_clazz.find(@b.id)
      a.known_by.size.should == 1
      a.known_by.should include(b)
      b.friends.size.should == 1
      b.friends.should include(a)
    end

    it "can be found using incoming and outgoing" do
      @b.outgoing(:friends).size.should == 1
      @b.outgoing(:friends).should include(@a)
      @a.incoming(:friends).size.should == 1
      @a.incoming(:friends).should include(@b)
    end

    it "can be found using incoming and outgoing also when reloaded nodes" do
      a = @a_clazz.find(@a.id)
      b = @b_clazz.find(@b.id)

      b.outgoing(:friends).size.should == 1
      b.outgoing(:friends).should include(a)
      a.incoming(:friends).size.should == 1
      a.incoming(:friends).should include(b)
    end

  end

  describe "has_n generated setter" do
    let(:sugar) { Ingredient.new :name => 'sugar' }
    let(:brown_sugar) { Ingredient.new :name => 'brown sugar' }

    context "when node is new" do
      it "should create relations to associated nodes" do
        icecream = IceCream.new

        icecream.ingredients = [sugar, brown_sugar]

        icecream.ingredients.to_a.should =~ [sugar, brown_sugar]
      end
    end

    context "creating a node with associated nodes" do
      it "should create relations to associated nodes" do
        icecream = IceCream.create!(:flavour => "Yummy!", :ingredients => [sugar, brown_sugar])

        icecream.ingredients.to_a.should =~ [sugar, brown_sugar]
        icecream.reload.ingredients.to_a.should =~ [sugar, brown_sugar]
      end
    end

    context "assinging associated nodes to node with existing associations" do
      it "should delete old relations and create new relations to associated nodes" do
        icecream = IceCream.create!(:flavour => "Yummy!", :ingredients => [brown_sugar])

        icecream.ingredients = [sugar]

        icecream.ingredients.to_a.should == [sugar]
        icecream.save!
        icecream.reload.ingredients.to_a.should == [sugar]
      end
    end
  end

  describe "has_one, has_n, outgoing" do
    it "node.friends << MyModel.create; node.save! should work" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      a.friends << b << c
      a.save!
      a.friends.size.should == 2
      a.friends.should include(b, c)

      # it should be persisted
      x = clazz.find(a.neo_id)
      x.friends.size.should == 2
    end

    it "should find the relationship using #outgoing method" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      a.friends << b << c
      a.save!

      a.outgoing(:friends).size.should == 2
      a.outgoing(:friends).should include(b, c)
    end


    it "should find the relationship using #has_n method when created with outgoing method" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      # need to create a new transaction since the node is already peristed
      new_tx
      a.outgoing(:friends) << b << c
      finish_tx
      a.friends.should include(b, c)
      a.save!
      a.friends.should include(b, c)
    end

    it "should find the relationship using #has_n friends_rels method when created with outgoing method" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      a.friends << b << c

      a.friends_rels.to_a.size.should == 2
      a.save!
      a.friends_rels.to_a.size.should == 2
    end

    it "should only find both persisted and none persisted relationship before saving it" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      a.friends << b << c
      a.save!
      d = clazz.new
      a.friends << d
      a.friends_rels.to_a.size.should == 3
      a.friends.to_a.size.should == 3
      # only one is none persisted
      a.friends.collect { |x| x.persisted? }.should == [false, true, true]
      a.save!
      a.friends_rels.to_a.size.should == 3
    end


    it "#save is necessary to create relationships" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      a.friends << b << c
      a.friends.size.should == 2
      a.friends.should include(b, c)

      # it should not be persiested
      x = clazz.find(a.neo_id)
      x.friends.size.should == 0
    end

    it "#del deletes the relationship without needing to call save" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      a.friends << b
      a.save
      a.outgoing(:friends).should include(b)

      rel = a.rels(:friends).outgoing.find(b)
      Neo4j::Transaction.run { rel.del }
      a.outgoing(:friends).should_not include(b)
    end

    it "has_n: should be empty when it has no relationships" do
      clazz = create_model
      clazz.has_n(:knows)
      jack = clazz.new
      jack.knows.should be_empty
    end

    it "has_one: should be empty when it has no relationships" do
      clazz = create_model
      clazz.has_one :thing
      jack = clazz.new
      jack.thing.should be_nil
    end

    it "add nodes to a has_one method with the #new method" do
      member = Member.new
      avatar = Avatar.new
      member.avatar = avatar
      member.avatar.should be_kind_of(Avatar)
      member.save
      member.avatar.id.should_not be_nil
    end

    it "has_one should allow assignments to nil" do
      member = Member.new
      member.avatar = nil
      member.avatar.should be_nil
      member.save
      member.reload.avatar.should be_nil
    end

    it "has_one should allow changing a value to nil from a non nil value" do
      member = Member.new
      member.avatar = Avatar.new
      member.save
      member.reload.avatar = nil
      member.save
      member.reload.avatar.should be_nil
    end

    it "adding nodes to a has_n method created with the #new method" do
      icecream = IceCream.new
      sugar = Ingredient.new :name => 'sugar'
      icecream.ingredients << sugar
      icecream.ingredients.should include(sugar)
    end

    it "adding nodes using outgoing should work for models created with the #new method" do
      icecream = IceCream.new
      sugar = Ingredient.new :name => 'sugar'
      icecream.outgoing(:ingredients) << sugar
      icecream.outgoing(:ingredients).should include(sugar)
    end

    it "saving the node should create all the nested nodes" do
      icecream = IceCream.new(:flavour => 'vanilla')
      sugar = Ingredient.new :name => 'sugar'
      butter = Ingredient.new :name => 'butter'

      icecream.ingredients << sugar << butter
      icecream.ingredients.should include(sugar, butter)

      sugar.neo_id.should == nil
      icecream.save.should be_true

      # then
      sugar.neo_id.should_not be_nil
      icecream.ingredients.should include(sugar, butter)

      # make sure the nested nodes were properly saved
      ice = IceCream.load(icecream.neo_id)
      ice.ingredients.should include(sugar, butter)
      icecream.ingredients.first.should be_kind_of(Ingredient)
    end

    it "should not save nested nodes if it was not valid" do
      icecream = IceCream.new # not valid
      sugar = Ingredient.new :name => 'sugar'
      butter = Ingredient.new :name => 'butter'

      icecream.ingredients << sugar << butter
      icecream.ingredients.should include(sugar, butter)

      sugar.neo_id.should == nil
      icecream.save.should be_false

      # then
      icecream.ingredients.should include(sugar, butter)

      sugar.neo_id.should == nil
    end

    describe "nested nodes two level deep" do
      before(:all) do
        @clazz = create_model do
          property :name
          has_n :knows
          validates :name, :presence => true
        end
      end

      it "deleting relationships only when save is called" do
        jack = @clazz.new(:name => 'jack')
        carol = @clazz.new(:name => 'carol')
        bob = @clazz.new(:name => 'bob')

        jack.knows << carol
        carol.knows << bob
        jack.knows << bob
        jack.knows_rels.first.delete
        jack.knows_rels.to_a.size.should == 2

        jack.save.should be_true

        # the knows_rels only support persisted relationships for now
        jack.knows_rels.to_a.size.should == 2
        jack.knows_rels.first.destroy
        jack.reload
      end
    end

    describe "has_one incoming" do
      it "should allow assignments to nil" do
        child_class = create_model
        parent_class = create_model { has_n(:children).to(child_class) }
        child_class.class_eval { has_one(:parent).from(parent_class, :children) }

        child = child_class.new
        child.parent = nil
        child.parent.should be_nil

        child.save
        child.reload.parent.should be_nil
      end
    end

    describe "accepts_nested_attributes_for" do

      class Avatar < Neo4j::Model
        property :icon
      end

      class Post < Neo4j::Model
        property :title
      end

      class Description < Neo4j::Model
        property :title
        property :text
        validates_presence_of :title

        def to_s
          "Description title: #{title} text:#{text}"
        end
      end

      class Member < Neo4j::Model
        has_n(:posts).to(Post)
        has_n(:valid_posts).to(Post)
        has_n(:valid_posts2).to(Post)
        has_n(:descriptions).to(Description)

        has_one(:avatar).to(Avatar)

        has_one(:thing)


        accepts_nested_attributes_for :descriptions
        accepts_nested_attributes_for :avatar, :allow_destroy => true
        accepts_nested_attributes_for :posts, :allow_destroy => true
        accepts_nested_attributes_for :valid_posts, :reject_if => proc { |attributes| attributes[:title].blank? }
        accepts_nested_attributes_for :valid_posts2, :reject_if => :reject_posts
        validates_associated :descriptions

        def reject_posts(attributed)
          attributed[:title].blank?
        end

      end

      it "create one-to-one " do
        params = {:member => {:name => 'Jack', :avatar_attributes => {:icon => 'smiling'}}}
        member = Member.create(params[:member])
        member.avatar.icon.should == 'smiling'

        member = Member.new(params[:member])
        member.save
        member.avatar.icon.should == 'smiling'
      end


      it "create one-to-one  - it also allows you to update the avatar through the member:" do
        params = {:member => {:name => 'Jack', :avatar_attributes => {:icon => 'smiling'}}}
        member = Member.create(params[:member])

        params = {:member => {:avatar_attributes => {:id => member.avatar.id, :icon => 'sad'}}}
        member.update_attributes params[:member]
        member.avatar.icon.should == 'sad'
      end

      it "create one-to-one - allows assigning avatars that have already been created" do
        avatar = Avatar.create(:icon => 'angry')
        params = {:member => {:name => 'Jack', :avatar_attributes => {:id => avatar.id}}}
        member = Member.create(params[:member])
        member.avatar.should == avatar
        member.avatar.icon.should == 'angry'
      end

      it "create one-to-one - allows updating avatars that have already been created" do
        avatar = Avatar.create(:icon => 'angry')
        params = {:member => {:name => 'Jack', :avatar_attributes => {:id => avatar.id, :icon => 'happy'}}}
        member = Member.create(params[:member])
        member.avatar.id.should == avatar.id
        member.avatar.icon.should == 'happy'
      end

      it "create one-to-one  - when you add the _destroy key to the attributes hash, with a value that evaluates to true, you will destroy the associated model" do
        params = {:member => {:name => 'Jack', :avatar_attributes => {:icon => 'smiling'}}}
        member = Member.create(params[:member])
        member.avatar.should_not be_nil

        # when
        member.avatar_attributes = {:id => member.avatar.id, :_destroy => '1'}
        member.save
        member.avatar.should be_nil
      end

      it "create one-to-one  - when you add the _destroy key of value '0' to the attributes hash you will NOT destroy the associated model" do
        params = {:member => {:name => 'Jack', :avatar_attributes => {:icon => 'smiling'}}}
        member = Member.create(params[:member])
        member.avatar.should_not be_nil

        # when
        member.avatar_attributes = {:id => member.avatar.id, :_destroy => '0'}
        member.save
        member.avatar.should_not be_nil
      end

      it "create one-to_many - You can now set or update attributes on an associated post model through the attribute hash" do
        # For each hash that does not have an id key a new record will be instantiated, unless the hash also contains a _destroy key that evaluates to true.
        params = {:member => {
            :name => 'joe', :posts_attributes => [
                {:title => 'Kari, the awesome Ruby documentation browser!'},
                {:title => 'The egalitarian assumption of the modern citizen'},
                {:title => '', :_destroy => '1'} # this will be ignored
            ]
        }}

        member = Member.create(params[:member])
        member.posts.size.should == 2
        member.posts.first.title.should == 'Kari, the awesome Ruby documentation browser!'
        member.posts[1].title.should == 'The egalitarian assumption of the modern citizen'

        member = Member.new(params[:member])
        member.posts.first.title.should == 'Kari, the awesome Ruby documentation browser!'
        member.posts[1].title.should == 'The egalitarian assumption of the modern citizen'
      end


      it ":reject_if proc will silently ignore any new record hashes if they fail to pass your criteria." do
        params = {:member => {
            :name => 'joe', :valid_posts_attributes => [
                {:title => 'Kari, the awesome Ruby documentation browser!'},
                {:title => 'The egalitarian assumption of the modern citizen'},
                {:title => ''} # this will be ignored because of the :reject_if proc
            ]
        }}

        member = Member.create(params[:member])
        member.valid_posts.length.should == 2
        member.valid_posts.first.title.should == 'Kari, the awesome Ruby documentation browser!'
        member.valid_posts[1].title.should == 'The egalitarian assumption of the modern citizen'
      end


      it ":reject_if also accepts a symbol for using methods" do
        params = {:member => {
            :name => 'joe', :valid_posts2_attributes => [
                {:title => 'Kari, the awesome Ruby documentation browser!'},
                {:title => 'The egalitarian assumption of the modern citizen'},
                {:title => ''} # this will be ignored because of the :reject_if proc
            ]
        }}

        member = Member.create(params[:member])
        member.valid_posts2.length.should == 2
        member.valid_posts2.first.title.should == 'Kari, the awesome Ruby documentation browser!'
        member.valid_posts2[1].title.should == 'The egalitarian assumption of the modern citizen'

        member = Member.new(params[:member])
        member.valid_posts2.first.title.should == 'Kari, the awesome Ruby documentation browser!'
        member.valid_posts2[1].title.should == 'The egalitarian assumption of the modern citizen'
        member.save
        member.valid_posts2.length.should == 2
        member.valid_posts2.first.title.should == 'Kari, the awesome Ruby documentation browser!'
        member.valid_posts2[1].title.should == 'The egalitarian assumption of the modern citizen'
      end


      it "If the hash contains an id key that matches an already associated record, the matching record will be modified:" do
        params = {:member => {
            :name => 'joe', :posts_attributes => [
                {:title => 'Kari, the awesome Ruby documentation browser!'},
                {:title => 'The egalitarian assumption of the modern citizen'},
                {:title => '', :_destroy => '1'} # this will be ignored
            ]
        }}

        member = Member.create(params[:member])

        # when
        id1 = member.posts[0].id
        id2 = member.posts[1].id

        member.attributes = {
            :name => 'Joe',
            :posts_attributes => [
                {:id => id1, :title => '[UPDATED] An, as of yet, undisclosed awesome Ruby documentation browser!'},
                {:id => id2, :title => '[UPDATED] other post'}
            ]
        }

        # then
        member.posts.first.title.should == '[UPDATED] An, as of yet, undisclosed awesome Ruby documentation browser!'
        member.posts[1].title.should == '[UPDATED] other post'
      end

      it "If the hash contains an id key that matches existing records, the matching records will associated" do
        post1 = Post.create(:title => "First Old post")
        post2 = Post.create(:title => "Second Old post")
        params = {:member => {
            :name => 'joe', :posts_attributes => [
                {:id => post1.id},
                {:id => post2.id}
            ]
        }}

        member = Member.create(params[:member])

        member.posts[0].id.should == post1.id
        member.posts[1].id.should == post2.id

        member.posts.first.title.should == 'First Old post'
        member.posts[1].title.should == 'Second Old post'
      end

      it "If the hash contains a mix of existing and new records, the existing record will be updated, and a new record will be created" do
        post1 = Post.create(:title => "First Old post")
        params = {:member => {
            :name => 'joe', :posts_attributes => [
                {:id => post1.id, :title => "Updated first Old post"},
                {:title => "New post"}
            ]
        }}

        member = Member.create(params[:member])

        member.posts[0].id.should == post1.id

        member.posts.first.title.should == 'Updated first Old post'
        member.posts[1].title.should == 'New post'
      end
    end
  end

end


describe RelationshipWithNoProperty do
  before(:each) do
    @start_node = Neo4j::Model.new
    @end_node = Neo4j::Model.new
  end

  subject do
    RelationshipWithNoProperty.new(:foo, @start_node, @end_node)
  end

  it "should persist" do
    subject.save
    RelationshipWithNoProperty._all.size.should == 1
    subject.class.all.to_a.size.should == 1
  end

  it_should_behave_like "a new model"
  it_should_behave_like "a loadable model"
  it_should_behave_like "a saveable model"
  it_should_behave_like "a creatable relationship model"
  it_should_behave_like "a destroyable model"
  it_should_behave_like "an updatable model"

  context "when there's lots of them" do
    before(:each) do
      subject.class.create!(:foo, @start_node, @end_node)
      subject.class.create!(:foo, @start_node, @end_node)
      subject.class.create!(:foo, @start_node, @end_node)
    end

    it "should be possible to #count" do
      subject.class.count.should == 4
    end

    it "should be possible to #destroy_all" do
      subject.class.all.to_a.size.should == 4
      subject.class.destroy_all
      subject.class.all.to_a.should be_empty
    end
  end
end


class RelationshipWithProperty < Neo4j::Rails::Relationship
  property :flavour
  index :flavour
  property :required_on_create
  property :required_on_update
  property :created

  attr_reader :saved

  validates :flavour, :presence => true
  validates :required_on_create, :presence => true, :on => :create
  validates :required_on_update, :presence => true, :on => :update

  before_create :timestamp
  after_create :mark_saved

  protected
  def timestamp
    self.created = "yep"
  end

  def mark_saved
    @saved = true
  end

end

describe RelationshipWithProperty do
  before(:each) do
    @start_node = Neo4j::Model.new
    @end_node = Neo4j::Model.new
  end

  subject do
    RelationshipWithProperty.new(:foo, @start_node, @end_node)
  end

  context "when valid" do
    before :each do
      subject.flavour = "vanilla"
      subject.required_on_create = "true"
      subject.required_on_update = "true"
      subject["new_attribute"] = "newun"
    end

    it_should_behave_like "a new model"
    it_should_behave_like "a loadable model"
    it_should_behave_like "a saveable model"
    it_should_behave_like "a creatable relationship model"
    it_should_behave_like "a destroyable model"
    it_should_behave_like "an updatable model"

    context "after being saved" do
      before { subject.save }

      it { should == subject.class.find('flavour: vanilla') }

      it "should render as XML" do
        subject.to_xml.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<relationship-with-property>\n  <flavour>vanilla</flavour>\n  <required-on-create>true</required-on-create>\n  <required-on-update>true</required-on-update>\n  <new-attribute>newun</new-attribute>\n  <created>yep</created>\n</relationship-with-property>\n"
      end

      it "should be able to modify one of its named attributes" do
        lambda { subject.update_attributes!(:flavour => 'horse') }.should_not raise_error
        subject.flavour.should == 'horse'
      end

      it "should not have the extended property" do
        subject.attributes.should_not include("extended_property")
      end

      it "should have the new attribute" do
        subject.attributes.should include("new_attribute")
        subject.attributes["new_attribute"].should == "newun"
        subject["new_attribute"].should == "newun"
      end

      it "should have the new attribute after find" do
        obj = subject.class.find('flavour: vanilla')
        obj.attributes.should include("new_attribute")
        obj.attributes["new_attribute"].should == "newun"
      end

      it "should respond to class.all" do
        subject.class.respond_to?(:all)
      end

      it "should respond to class#all(:flavour => 'vanilla')" do
        subject.class.all('flavour: vanilla').should include(subject)
      end

      it "should also be included in the rules for the parent class" do
        pending
        subject.class.superclass.all.to_a.should include(subject)
      end

      context "and then made invalid" do
        before { subject.required_on_update = nil }

        it "shouldn't be updatable" do
          subject.update_attributes(:flavour => "fish").should_not be_true
        end

        it "should have the same attribute values after an unsuccessful update and reload" do
          subject.update_attributes(:flavour => "fish")
          subject.reload.flavour.should == "vanilla"
          subject.required_on_update.should_not be_nil
        end

        it "shouldn't have a new attribute after an unsuccessful update and reload" do
          subject["this_is_new"] = "test"
          subject.attributes.should include("this_is_new")
          subject.update_attributes(:flavour => "fish")
          subject.reload.flavour.should == "vanilla"
          subject.required_on_update.should_not be_nil
          subject.attributes.should_not include("this_is_new")
        end
      end
    end

    context "after create" do
      before :each do
        @obj = subject.class.create!(:foo, @start_node, @end_node, subject.attributes)
      end

      it "should have run the #timestamp callback" do
        @obj.created.should_not be_nil
      end

      it "should have run the #mark_saved callback" do
        @obj.saved.should_not be_nil
      end
    end


  end

  context "when invalid" do
    it_should_behave_like "a new model"
    it_should_behave_like "an unsaveable model"
    it_should_behave_like "an uncreatable model"
    it_should_behave_like "a non-updatable model"
  end

end


describe "SettingRelationship" do

  context "created with Neo4j::Rails::Relationship" do
    before(:all) do
      @actor_class = create_model(Neo4j::Model)
      @actor_class.property :name
      @movie_class = create_model(Neo4j::Model)
      @movie_class.property :title
      @actor_class.has_n(:acted_in)
      @movie_class.has_n(:actors).from(:acted_in)
    end

    it "can be created with Neo4j::Rails::Relationship.create" do
      actor = @actor_class.new
      movie = @movie_class.new
      Neo4j::Rails::Relationship.new(@actor_class.acted_in, actor, movie)
      actor.acted_in.size.should == 1
      actor.acted_in.should include(movie)
      movie.actors.size.should == 1
      movie.actors.should include(actor)
    end

  end


  context "create a Neo4j::Rails::Relationship" do
    before(:each) do
      @start_node = NodeWithRelationship.new
      @end_node = Neo4j::Rails::Model.new
    end

    it "has_n" do
      @start_node.outgoing(:baaz) << Neo4j::Rails::Model.new
      @start_node.baaz.size.should == 1
      @start_node.save
      @start_node.baaz.size.should == 1
      @start_node.outgoing(:baaz).to_a.size.should == 1

      @start_node.outgoing(:baaz) << Neo4j::Rails::Model.new
      @start_node.outgoing(:baaz).to_a.size.should == 2
      @start_node.baaz.size.should == 2
      @start_node.save
      @start_node.baaz.size.should == 2
    end


    it "add an outgoing should set the incoming" do
      @start_node.outgoing(:other_node) << @end_node
      @end_node.incoming(:other_node).first.should == @start_node
    end

    it "add an incoming should set the outgoing" do
      @start_node.incoming(:other_node) << @end_node
      @end_node.outgoing(:other_node).first.should == @start_node
      @start_node.save
      @end_node.should be_persisted
      @start_node.should be_persisted
      @end_node.outgoing(:other_node).first.should == @start_node
      @start_node.incoming(:other_node).first.should == @end_node
      @end_node.outgoing(:other_node).to_a.size.should == 1
      @start_node.incoming(:other_node).to_a.size.should == 1

      # and again with
      @start_node = Neo4j::Node.load(@start_node.neo_id)
      @end_node = Neo4j::Node.load(@end_node.neo_id)
      @end_node.should be_persisted
      @start_node.should be_persisted
      @end_node.outgoing(:other_node).first.should == @start_node
      @start_node.incoming(:other_node).first.should == @end_node
      @end_node.outgoing(:other_node).to_a.size.should == 1
      @start_node.incoming(:other_node).to_a.size.should == 1
    end

    it "add an outgoing should set the outgoing" do
      @start_node.outgoing(:other_node) << @end_node
      @end_node.incoming(:other_node).first.should == @start_node
      @start_node.save
      @end_node.should be_persisted
      @start_node.should be_persisted
      @end_node.incoming(:other_node).first.should == @start_node
      @start_node.outgoing(:other_node).first.should == @end_node
    end

    it "adding many different relationships" do
      @start_node.outgoing(:foo) << (c = Neo4j::Rails::Model.new)
      @start_node.outgoing(:other_node) << (a = Neo4j::Rails::Model.new)
      @start_node.outgoing(:other_node) << (b = Neo4j::Rails::Model.new)

      @start_node.outgoing(:foo).size.should == 1
      @start_node.outgoing(:foo).should include(c)

      @start_node.outgoing(:other_node).size.should == 2
      @start_node.outgoing(:other_node).should include(a, b)

      c.incoming(:foo).size.should == 1
      c.incoming(:foo).should include(@start_node)
      b.incoming(:other_node).size.should == 1
      b.incoming(:other_node).should include(@start_node)
      a.incoming(:other_node).size.should == 1
      a.incoming(:other_node).should include(@start_node)
      @start_node.relationships_changed?.should be_true
      @start_node.save
      @start_node.relationships_changed?.should be_false

      @start_node.outgoing(:foo).size.should == 1
      @start_node.outgoing(:foo).should include(c)

      @start_node.outgoing(:other_node).size.should == 2
      @start_node.outgoing(:other_node).should include(a, b)

      c.incoming(:foo).size.should == 1
      c.incoming(:foo).should include(@start_node)
      b.incoming(:other_node).size.should == 1
      b.incoming(:other_node).should include(@start_node)
      a.incoming(:other_node).size.should == 1
      a.incoming(:other_node).should include(@start_node)
    end

    it "add an outgoing twice should set the outgoing" do
      @start_node.outgoing(:other_node) << @end_node
      @start_node.outgoing(:other_node).size.should == 1
      @end_node.incoming(:other_node).size.should == 1
      @start_node.save
      @start_node.outgoing(:other_node).size.should == 1
      @end_node.incoming(:other_node).size.should == 1

      @start_node.outgoing(:other_node) << Neo4j::Rails::Model.new
      @start_node.outgoing(:other_node).size.should == 2
      @end_node.incoming(:other_node).size.should == 1
      @start_node.save
      @end_node.should be_persisted
      @start_node.should be_persisted

      @start_node.outgoing(:other_node).size.should == 2
      @end_node.incoming(:other_node).size.should == 1
    end

    it "should find the relationship using #incoming method" do
      clazz = create_model
      a = clazz.create
      b = clazz.create
      c = clazz.create
      a.outgoing(:qwe) << b
      a.outgoing(:qwe) << c
      a.outgoing(:qwe).size.should == 2
      b.incoming(:qwe).size.should == 1
      b.outgoing(:qwe).size.should == 0
      c.incoming(:qwe).size.should == 1
      c.outgoing(:qwe).size.should == 0
      b.incoming(:qwe).should include(a)
      c.incoming(:qwe).should include(a)
      a.save
      a.outgoing(:qwe).size.should == 2
      b._java_node.incoming(:qwe).size.should == 1
      b.incoming(:qwe).size.should == 1
      b.outgoing(:qwe).size.should == 0
      c.incoming(:qwe).size.should == 1
      c.outgoing(:qwe).size.should == 0
      b.incoming(:qwe).should include(a)
      c.incoming(:qwe).should include(a)
    end
  end


  context "setting a Neo4j::Rails::Relationship" do
    subject { @start_node.other_node_rel } #@start_node.other_node_rel }

    before(:each) do
      @start_node = NodeWithRelationship.new
      @end_node = Neo4j::Rails::Model.new
      @start_node.other_node = @end_node
    end

    it { should be_kind_of(Neo4j::Rails::Relationship) }
    it_should_behave_like "a relationship model"
  end

  context "setting has many" do

    it "bla" do
      @start_node = NodeWithRelationship.new
      @end_node_1 = Neo4j::Rails::Model.new
      @end_node_2 = Neo4j::Rails::Model.new
      @start_node.baaz << @end_node_1 << @end_node_2

      @start_node.baaz_rels.each do |rel|
        rel.should be_kind_of(Neo4j::Rails::Relationship)
      end
      @start_node.baaz_rels.to_a.size.should == 2
      @start_node.baaz.should include(@end_node_1, @end_node_2)
      @start_node.save
      @start_node.baaz_rels.each do |rel|
        rel.should be_kind_of(Neo4j::Rails::Relationship)
      end
      @start_node.baaz_rels.to_a.size.should == 2
      @start_node.baaz.should include(@end_node_1, @end_node_2)
    end

  end

  context "setting RelationshipWithNoProperty" do
    subject { @start_node.foobar_rel } #@start_node.other_node_rel }

    before(:each) do
      @start_node = NodeWithRelationship.new
      @end_node = Neo4j::Rails::Model.new
      @start_node.foobar = @end_node
    end

    it { should be_kind_of(RelationshipWithNoProperty) }

    it "should create the correct relationship class after save" do
      @start_node.foobar_rel.should be_kind_of(RelationshipWithNoProperty)
      @start_node.save
      @start_node.foobar_rel.should be_kind_of(RelationshipWithNoProperty)
    end

    it_should_behave_like "a relationship model"

    it "should have no incoming" do
      @start_node.rels(:foobar).incoming.should be_empty
      @start_node.rels(:foobar).outgoing.size.should == 1
    end
  end

  describe "update" do
    context "when validates associated" do
      context "when a nested model is invalid" do
        it "should make parent model invalid" do
          description = Description.create!(:title => 'Title', :text => "First description")
          member = Member.create.tap do |member|
            member.descriptions << description
            member.save
          end
          member.update_attributes(:descriptions_attributes => {"0" => {:id => description.id, :title => nil}})
          member.errors.should be_present
          member.errors[:descriptions].should include("is invalid")
          member.descriptions.size.should == 1
          member_description = member.descriptions.first
          member_description.should be_invalid
          member_description.errors[:title].should include("can't be blank")
          member.update_attributes(:descriptions_attributes => {"0" => {:id => description.id, :title => "New title"}})
          member.errors.should_not be_present
        end

        it "should allow delete_all" do
          description = Description.create!(:title => 'Title', :text => "First description")
          member = Member.create.tap do |member|
            member.descriptions << description
            member.save
            member.descriptions.delete_all
            member.descriptions << description
            member.save
          end
          member.descriptions.first.should == description
          member.errors.should_not be_present
        end
      end
    end
  end
end
