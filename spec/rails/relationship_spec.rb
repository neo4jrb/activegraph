require File.join(File.dirname(__FILE__), '..', 'spec_helper')


class RelationshipWithNoProperty < Neo4j::Rails::Relationship
end


describe "Neo4j::Model Relationships" do
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
      a.friends.collect{|x| x.persisted?}.should == [false, true, true]
      a.save!
      a.friends_rels.to_a.size.should == 3
    end


    it "#save is neccessarly to create relationships" do
      clazz = create_model
      clazz.has_n(:friends)
      a = clazz.create
      b = clazz.create
      c = clazz.create

      a.friends << b << c
      a.friends.size.should == 2
      a.friends.should include(b,c)

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

      rel = a.rels(:friends).outgoing.to_other(b).first
      Neo4j::Transaction.run { rel.del }
      a.outgoing(:friends).should_not include(b)
    end

    it "has_n: should be empty when it has no relationships" do
      clazz = create_model
      clazz.has_n(:knows)
      jack  = clazz.new
      jack.knows.should be_empty
    end

    it "has_one: should be empty when it has no relationships" do
      clazz = create_model
      clazz.has_one :thing
      jack  = clazz.new
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

    it "adding nodes to a has_n method created with the #new method" do
      icecream = IceCream.new
      suger = Ingredience.new :name => 'suger'
      icecream.ingrediences << suger
      icecream.ingrediences.should include(suger)
    end

    it "adding nodes using outgoing should work for models created with the #new method" do
      icecream = IceCream.new
      suger = Ingredience.new :name => 'suger'
      icecream.outgoing(:ingrediences) << suger
      icecream.outgoing(:ingrediences).should include(suger)
    end

    it "saving the node should create all the nested nodes" do
      icecream = IceCream.new(:flavour => 'vanilla')
      suger  = Ingredience.new :name => 'suger'
      butter = Ingredience.new :name => 'butter'

      icecream.ingrediences << suger << butter
      icecream.ingrediences.should include(suger, butter)

      suger.neo_id.should == nil
      icecream.save.should be_true

      # then
      suger.neo_id.should_not be_nil
      icecream.ingrediences.should include(suger, butter)

      # make sure the nested nodes were properly saved
      ice = IceCream.load(icecream.neo_id)
      ice.ingrediences.should include(suger, butter)
      icecream.ingrediences.first.should be_kind_of(Ingredience)
    end

    it "should not save nested nodes if it was not valid" do
      icecream = IceCream.new # not valid
      suger  = Ingredience.new :name => 'suger'
      butter = Ingredience.new :name => 'butter'

      icecream.ingrediences << suger << butter
      icecream.ingrediences.should include(suger, butter)

      suger.neo_id.should == nil
      icecream.save.should be_false

      # then
      icecream.ingrediences.should include(suger, butter)

      suger.neo_id.should == nil
   end

   it "should return false if one of the nested nodes is invalid when saving all of them" do
      suger  = Ingredience.new :name => 'suger'
      icecream2 = IceCream.new # not valid

      # when
      suger.outgoing(:related_icecreams) << icecream2

      # then
      suger.save.should be_false
    end

    it "errors should contain aggregated errors if one of the nested nodes is invalid when saving all of them" do
       suger  = Ingredience.new :name => 'suger'
       icecream2 = IceCream.new # not valid

       # when
       suger.outgoing(:related_icecreams) << icecream2

       # then
       suger.save
       suger.outgoing(:related_icecreams).should include(icecream2)
       suger.errors[:related_icecreams].first.should include(:flavour)
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
        jack  = @clazz.new(:name => 'jack')
        carol = @clazz.new(:name => 'carol')
        bob   = @clazz.new(:name => 'bob')

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

      it "when one nested node is invalid it should not save any nodes" do
        jack  = @clazz.new(:name => 'jack')
        carol = @clazz.new(:name => 'carol')
        bob   = @clazz.new # invalid

        jack.knows << carol
        carol.knows << bob
        jack.knows << bob

        lambda do
          jack.save.should be_false
        end.should_not change([*Neo4j.all_nodes], :size)

        finish_tx
        Neo4j.all_nodes.should_not include(jack)
        Neo4j.all_nodes.should_not include(bob)
        Neo4j.all_nodes.should_not include(carol)
      end

      it "when one nested node is invalid it should not update any nodes" do
        jack  = @clazz.new(:name => 'jack')
        carol = @clazz.new(:name => 'carol')
        bob   = @clazz.new # invalid

        jack.knows << carol
        jack.save! # save all

        # when
        jack.name = 'changed'
        jack.knows << bob # invalid

        # then
        jack.save.should be_false
        jack.knows.should include(carol)
        jack.knows.should include(bob)
        jack.reload
        jack.knows.should include(carol)
        jack.knows.should_not include(bob)
        jack.name.should == 'jack'
      end

      it "only when all nested nodes are valid all the nodes will be saved" do
        jack  = @clazz.new(:name => 'jack')
        carol = @clazz.new(:name => 'carol')
        bob   = @clazz.new(:name => 'bob')

        jack.knows << carol
        carol.knows << bob
        jack.knows << bob

        lambda do
          jack.save.should be_true
        end.should_not change([*Neo4j.all_nodes], :size).by(3)

        finish_tx
        Neo4j.all_nodes.should include(jack, carol, bob)
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

        def reject_posts(attributed)
          attributed[:title].blank?
        end

      end

      it "does not save invalid nested nodes" do
        params = {:member => {:name => 'Jack', :avatar_attributes => {:icon => 'smiling'}}}
        member = Member.create(params[:member])
        params = {:member => {:descriptions_attributes => [{:text => 'bla bla bla'}]}}
        member.update_attributes(params[:member]).should be_false
        member.reload
        member.descriptions.should be_empty
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
        params            = {:member => {
            :name => 'joe', :posts_attributes => [
                {:title => 'Kari, the awesome Ruby documentation browser!'},
                {:title => 'The egalitarian assumption of the modern citizen'},
                {:title => '', :_destroy => '1'} # this will be ignored
            ]
        }}

        member            = Member.create(params[:member])

        # when
        id1               = member.posts[0].id
        id2               = member.posts[1].id

        member.attributes = {
            :name             => 'Joe',
            :posts_attributes => [
                {:id => id1, :title => '[UPDATED] An, as of yet, undisclosed awesome Ruby documentation browser!'},
                {:id => id2, :title => '[UPDATED] other post'}
            ]
        }

        # then
        member.posts.first.title.should == '[UPDATED] An, as of yet, undisclosed awesome Ruby documentation browser!'
        member.posts[1].title.should == '[UPDATED] other post'
      end
    end
  end

end


#
#describe RelationshipWithNoProperty do
#  pending
#  before(:each) do
#    @start_node = Neo4j::Model.new
#    @end_node = Neo4j::Model.new
#  end
#
#  subject do
#    RelationshipWithNoProperty.new(:foo, @start_node, @end_node)
#  end
#
##  it "should persist" do
##    puts "a=#{@a}/#{@a.persisted?}, id:#{@a.object_id}"
##    puts "b=#{@b}/#{@b.persisted?}, id:#{@b.object_id}"
##    subject.save
##
##    RelationshipWithProperty._all.size.should == 1
##  end
#
#  it_should_behave_like "a new model"
#  it_should_behave_like "a loadable model"
#  it_should_behave_like "a saveable model"
#  it_should_behave_like "a creatable relationship model"
#  it_should_behave_like "a destroyable model"
#  it_should_behave_like "an updatable model"
#
#  context "when there's lots of them" do
#    before(:each) do
#      subject.class.create!(:foo, @start_node, @end_node)
#      subject.class.create!(:foo, @start_node, @end_node)
#      subject.class.create!(:foo, @start_node, @end_node)
#    end
#
#    it "should be possible to #count" do
#      subject.class.count.should == 3
#    end
#
#    it "should be possible to #destroy_all" do
#      subject.class.all.to_a.size.should == 3
#      subject.class.destroy_all
#      subject.class.all.to_a.should be_empty
#    end
#  end
#
#end
#
#
#
#class RelationshipWithProperty < Neo4j::Rails::Relationship
#  property :flavour
#  index :flavour
#  property :required_on_create
#  property :required_on_update
#  property :created
#
#  attr_reader :saved
#
#  validates :flavour, :presence => true
#  validates :required_on_create, :presence => true, :on => :create
#  validates :required_on_update, :presence => true, :on => :update
#
#  before_create :timestamp
#  after_create :mark_saved
#
#  protected
#  def timestamp
#    self.created = "yep"
#  end
#
#  def mark_saved
#    @saved = true
#  end
#
#end
#
#describe RelationshipWithProperty do
#  before(:each) do
#    @start_node = Neo4j::Model.new
#    @end_node = Neo4j::Model.new
#  end
#
#  subject do
#    RelationshipWithProperty.new(:foo, @start_node, @end_node)
#  end
#
#  context "when valid" do
#    before :each do
#      subject.flavour = "vanilla"
#      subject.required_on_create = "true"
#      subject.required_on_update = "true"
#      subject["new_attribute"] = "newun"
#    end
#
#    it_should_behave_like "a new model"
#    it_should_behave_like "a loadable model"
#    it_should_behave_like "a saveable model"
#    it_should_behave_like "a creatable relationship model"
#    it_should_behave_like "a destroyable model"
#    it_should_behave_like "an updatable model"
#
#    context "after being saved" do
#      before { subject.save }
#
#      it { should == subject.class.find('flavour: vanilla') }
#
#      it "should render as XML" do
#        subject.to_xml.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<relationship-with-property>\n  <flavour>vanilla</flavour>\n  <required-on-create>true</required-on-create>\n  <required-on-update>true</required-on-update>\n  <new-attribute>newun</new-attribute>\n  <created>yep</created>\n</relationship-with-property>\n"
#      end
#
#      it "should be able to modify one of its named attributes" do
#        lambda { subject.update_attributes!(:flavour => 'horse') }.should_not raise_error
#        subject.flavour.should == 'horse'
#      end
#
#      it "should not have the extended property" do
#        subject.attributes.should_not include("extended_property")
#      end
#
#      it "should have the new attribute" do
#        subject.attributes.should include("new_attribute")
#        subject.attributes["new_attribute"].should == "newun"
#        subject["new_attribute"].should == "newun"
#      end
#
#      it "should have the new attribute after find" do
#        obj = subject.class.find('flavour: vanilla')
#        obj.attributes.should include("new_attribute")
#        obj.attributes["new_attribute"].should == "newun"
#      end
#
#      it "should respond to class.all" do
#        subject.class.respond_to?(:all)
#      end
#
#      it "should respond to class#all(:flavour => 'vanilla')" do
#        subject.class.all('flavour: vanilla').should include(subject)
#      end
#
#      it "should also be included in the rules for the parent class" do
#        pending
#        subject.class.superclass.all.to_a.should include(subject)
#      end
#
#      context "and then made invalid" do
#        before { subject.required_on_update = nil }
#
#        it "shouldn't be updatable" do
#          subject.update_attributes(:flavour => "fish").should_not be_true
#        end
#
#        it "should have the same attribute values after an unsuccessful update and reload" do
#          subject.update_attributes(:flavour => "fish")
#          subject.reload.flavour.should == "vanilla"
#          subject.required_on_update.should_not be_nil
#        end
#
#        it "shouldn't have a new attribute after an unsuccessful update and reload" do
#          subject["this_is_new"] = "test"
#          subject.attributes.should include("this_is_new")
#          subject.update_attributes(:flavour => "fish")
#          subject.reload.flavour.should == "vanilla"
#          subject.required_on_update.should_not be_nil
#          subject.attributes.should_not include("this_is_new")
#        end
#      end
#    end
#
#    context "after create" do
#      before :each do
#        @obj = subject.class.create!(:foo, @start_node, @end_node, subject.attributes)
#      end
#
#      it "should have run the #timestamp callback" do
#        @obj.created.should_not be_nil
#      end
#
#      it "should have run the #mark_saved callback" do
#        @obj.saved.should_not be_nil
#      end
#    end
#
#
#  end
#
#  context "when invalid" do
#    it_should_behave_like "a new model"
#    it_should_behave_like "an unsaveable model"
#    it_should_behave_like "an uncreatable model"
#    it_should_behave_like "a non-updatable model"
#  end
#
#end
#
#
describe "SettingRelationship" do
  class NodeWithRelationship < Neo4j::Rails::Model
    has_one(:other_node) #.relationship(RelationshipWithNoProperty)
    has_one(:foobar).relationship(RelationshipWithNoProperty)
    has_n(:baaz)
  end

  context "create a Neo4j::Rails::Relationship" do
    before(:each) do
      @start_node = NodeWithRelationship.new
      @end_node = Neo4j::Rails::Model.new
    end

#    it "has_n" do
#      @start_node.outgoing(:baaz) << Neo4j::Rails::Model.new
#      @start_node.baaz.size.should == 1
#      @start_node.save
#      @start_node.baaz.size.should == 1
#      @start_node.outgoing(:baaz).to_a.size.should == 1
#
#      @start_node.outgoing(:baaz) << Neo4j::Rails::Model.new
#      @start_node.outgoing(:baaz).to_a.size.should == 2
#      @start_node.baaz.size.should == 2
#      @start_node.save
#      @start_node.baaz.size.should == 2
#    end
#
#
#    it "add an outgoing should set the incoming" do
#      @start_node.outgoing(:other_node) << @end_node
#      @end_node.incoming(:other_node).first.should == @start_node
#    end

    it "add an incoming should set the outgoing" do
      @start_node.incoming(:other_node) << @end_node
      @end_node.outgoing(:other_node).first.should == @start_node
      puts "-------- save"
      @start_node.save
      @end_node.should be_persisted
      @start_node.should be_persisted
      @end_node.outgoing(:other_node).first.should == @start_node
      @start_node.incoming(:other_node).first.should == @end_node
    end
  end
end

#    it "add an outgoing should set the outgoing" do
#      @start_node.outgoing(:other_node) << @end_node
#      @end_node.incoming(:other_node).first.should == @start_node
#      @start_node.save
#      @end_node.should be_persisted
#      @start_node.should be_persisted
#      @end_node.incoming(:other_node).first.should == @start_node
#      @start_node.outgoing(:other_node).first.should == @end_node
#    end
#
#    it "adding many different relationships" do
#      @start_node.outgoing(:foo) << (c = Neo4j::Rails::Model.new)
#      @start_node.outgoing(:other_node) << (a = Neo4j::Rails::Model.new)
#      @start_node.outgoing(:other_node) << (b = Neo4j::Rails::Model.new)
#
#      @start_node.outgoing(:foo).size.should == 1
#      @start_node.outgoing(:foo).should include(c)
#
#      @start_node.outgoing(:other_node).size.should == 2
#      @start_node.outgoing(:other_node).should include(a, b)
#
#      c.incoming(:foo).size.should == 1
#      c.incoming(:foo).should include(@start_node)
#      b.incoming(:other_node).size.should == 1
#      b.incoming(:other_node).should include(@start_node)
#      a.incoming(:other_node).size.should == 1
#      a.incoming(:other_node).should include(@start_node)
#      @start_node.save
#
#      @start_node.outgoing(:foo).size.should == 1
#      @start_node.outgoing(:foo).should include(c)
#
#      @start_node.outgoing(:other_node).size.should == 2
#      @start_node.outgoing(:other_node).should include(a, b)
#
#      c.incoming(:foo).size.should == 1
#      c.incoming(:foo).should include(@start_node)
#      b.incoming(:other_node).size.should == 1
#      b.incoming(:other_node).should include(@start_node)
#      a.incoming(:other_node).size.should == 1
#      a.incoming(:other_node).should include(@start_node)
#    end
#
#    it "add an outgoing twice should set the outgoing" do
#      @start_node.outgoing(:other_node) << @end_node
#      @start_node.outgoing(:other_node).size.should == 1
#      @end_node.incoming(:other_node).size.should == 1
#      @start_node.save
#      @start_node.outgoing(:other_node).size.should == 1
#      @end_node.incoming(:other_node).size.should == 1
#
#      @start_node.outgoing(:other_node) << Neo4j::Rails::Model.new
#      @start_node.outgoing(:other_node).size.should == 2
#      @end_node.incoming(:other_node).size.should == 1
#      @start_node.save
#      @end_node.should be_persisted
#      @start_node.should be_persisted
#
#      @start_node.outgoing(:other_node).size.should == 2
#      @end_node.incoming(:other_node).size.should == 1
#    end
#  end
#
#
#  context "setting a Neo4j::Rails::Relationship" do
#    subject { @start_node.other_node_rel } #@start_node.other_node_rel }
#
#    before(:each) do
#      @start_node = NodeWithRelationship.new
#      @end_node = Neo4j::Rails::Model.new
#      @start_node.other_node = @end_node
#    end
#
#    it { should be_kind_of(Neo4j::Rails::Relationship) }
#    it_should_behave_like "a relationship model"
#  end
#
#  context "setting has many" do
#
#    it "bla" do
#      @start_node = NodeWithRelationship.new
#      @end_node_1 = Neo4j::Rails::Model.new
#      @end_node_2 = Neo4j::Rails::Model.new
#      @start_node.baaz << @end_node_1 << @end_node_2
#
#      @start_node.baaz_rels.each do |rel|
#        rel.should be_kind_of(Neo4j::Rails::Relationship)
#      end
#      @start_node.baaz_rels.to_a.size.should == 2
#      @start_node.baaz.should include(@end_node_1, @end_node_2)
#      @start_node.save
#      @start_node.baaz_rels.each do |rel|
#        rel.should be_kind_of(Neo4j::Rails::Relationship)
#      end
#      @start_node.baaz_rels.to_a.size.should == 2
#      @start_node.baaz.should include(@end_node_1, @end_node_2)
#    end
#
#  end
#
#  context "setting RelationshipWithNoProperty" do
#    subject { @start_node.foobar_rel } #@start_node.other_node_rel }
#
#    before(:each) do
#      @start_node = NodeWithRelationship.new
#      @end_node = Neo4j::Rails::Model.new
#      @start_node.foobar = @end_node
#    end
#
#    it { should be_kind_of(RelationshipWithNoProperty) }
#
#    it "should create the correct relationship class after save" do
#      @start_node.save
#      @start_node.foobar_rel.should be_kind_of(RelationshipWithNoProperty)
#    end
#
#    it_should_behave_like "a relationship model"
#
#    it "should have no incoming" do
#      @start_node.rels(:foobar).incoming.should be_empty
#      @start_node.rels(:foobar).outgoing.size.should == 1
#    end
#  end
#end
##  context "other_node_rel" do
##    subject { @start_node.other_node_rel }
##
##    before(:each) do
##      @start_node = NodeWithRelationship.new
##      @end_node = Neo4j::Rails::Model.new
##      @start_node.other_node = @end_node
##    end
##
##    #it { should be_a(RelationshipWithNoProperty) }
##    it_should_behave_like "a relationship model"
##  end
##
##end
#
