# require 'spec_helper'

# describe "has_n" do

#   let(:clazz) do
#     UniqueClass.create do
#       include Neo4j::ActiveNode
#     end
#   end

#   let(:other_clazz) do
#     UniqueClass.create do
#       include Neo4j::ActiveNode
#     end
#   end

#   describe '#_decl_rels' do
#     it 'is a Hash' do
#       #clazz.has_n :friends
#       clazz._decl_rels.should be_a(Hash)
#     end

#     context 'when inherited' do
#       class TestHasNBase
#         include Neo4j::ActiveNode
#         has_n :knows
#       end

#       class TestHasNSub < TestHasNBase

#       end

#       it 'inherit declared has_n' do
#         TestHasNSub._decl_rels[:knows].should be_a(Neo4j::ActiveNode::HasN::DeclRel)
#       end

#       it 'impl has_n accessor methods' do
#         node = TestHasNSub.new
#         node.should respond_to(:knows)
#         node.should respond_to(:knows_rels)
#       end
#     end
#   end

#   describe 'has_n(:friends)' do
#     before do
#       clazz.has_n :friends
#     end

#     let(:core_node) do
#       double("core node", props: {})
#     end

#     let(:node) do
#       session.should_receive(:create_node).and_return(core_node)
#       clazz.create
#     end


#     let(:session) do
#       session = double("Mock Session")
#       Neo4j::Session.stub(:current).and_return(session)
#       session
#     end

#     describe 'clazz.friends' do
#       subject { clazz.friends }
#       it { should eq(:friends)}
#     end

#     describe 'node.friends << a_node' do

#       it 'creates a new relationship' do
#         a_node = double("a node")

#         node.should_receive(:create_rel).with(:friends, a_node, {})

#         # when
#         node.friends << a_node
#       end
#     end

#     describe 'node.friends = [a_node, b_node]' do

#       it 'creates a new relationship' do
#         a_node = double("a node")
#         b_node = double("b node")

#         node.should_receive(:rels).with({:dir=>:outgoing, :type=>:friends}).and_return([])

#         node.should_receive(:create_rel).with(:friends, a_node, {})
#         node.should_receive(:create_rel).with(:friends, b_node, {})

#         # when
#         node.friends = [a_node, b_node]
#       end
#     end

#     describe 'node.friends.to_a' do

#       it 'traverse correct relationships' do
#         core_node.should_receive(:nodes).with(dir: :outgoing, type: :friends).and_return([])
#         node.friends.to_a.should eq([])
#       end

#       it 'can return wrapped nodes' do
#         friend_node_wrapper = double("friend node wrapper")
#         core_node.should_receive(:nodes).with(dir: :outgoing, type: :friends).and_return([friend_node_wrapper])
#         node.friends.to_a.should eq([friend_node_wrapper])
#       end
#     end

#     describe '_decl_rels[:friends]' do
#       subject do
#         clazz._decl_rels[:friends]
#       end

#       it { should be_a(Neo4j::ActiveNode::HasN::DeclRel)}
#       its(:dir) { should eq(:outgoing)}
#       its(:source_class) { should eq(clazz)}
#       its(:rel_type) { should eq(:friends)}
#     end
#   end


#   describe 'has_n(:friends).to(OtherClass)' do
#     before do
#       clazz.has_n(:friends).to(other_clazz)
#     end

#     describe 'clazz.friends' do
#       subject { clazz.friends }
#       it { should eq(:"#{clazz}#friends")}
#     end

#     describe '_decl_rels[:friends]' do
#       subject do
#         clazz._decl_rels[:friends]
#       end

#       it { should be_a(Neo4j::ActiveNode::HasN::DeclRel) }
#       its(:dir) { should eq(:outgoing) }
#       its(:source_class) { should eq(clazz) }
#       its(:rel_type) { should eq(:"#{clazz}#friends") }
#     end
#   end

#   describe 'has_n(:known_by).from(OtherClass)' do
#     before do
#       clazz.has_n(:known_by).from(other_clazz)
#     end

#     describe 'clazz.known_by' do
#       subject { clazz.known_by }
#       it { should eq(:"#{other_clazz}#known_by")}
#     end

#     describe '_decl_rels[:known_by]' do
#       subject do
#         clazz._decl_rels[:known_by]
#       end

#       it { should be_a(Neo4j::ActiveNode::HasN::DeclRel) }
#       its(:dir) { should eq(:incoming) }
#       its(:source_class) { should eq(clazz) }
#       its(:rel_type) { should eq(:"#{other_clazz}#known_by") }
#     end

#   end

#   describe 'has_n(:known_by).from(OtherClass, :knows)' do
#     before do
#       clazz.has_n(:known_by).from(other_clazz, :knows)
#     end

#     describe 'clazz.known_by' do
#       subject { clazz.known_by }
#       it { should eq(:"#{other_clazz}#knows")}
#     end

#     describe '_decl_rels[:known_by]' do
#       subject do
#         clazz._decl_rels[:known_by]
#       end

#       it { should be_a(Neo4j::ActiveNode::HasN::DeclRel) }
#       its(:dir) { should eq(:incoming) }
#       its(:source_class) { should eq(clazz) }
#       its(:rel_type) { should eq(:"#{other_clazz}#knows") }
#     end

#   end

#   describe 'has_n(:known_by).from(:"OtherClass#knows")' do
#     before do
#       clazz.has_n(:known_by).from(:"OtherClass#knows")
#     end

#     describe 'clazz.known_by' do
#       subject { clazz.known_by }
#       it { should eq(:"OtherClass#knows")}
#     end

#     describe '_decl_rels[:known_by]' do
#       subject do
#         clazz._decl_rels[:known_by]
#       end

#       it { should be_a(Neo4j::ActiveNode::HasN::DeclRel) }
#       its(:dir) { should eq(:incoming) }
#       its(:source_class) { should eq(clazz) }
#       its(:rel_type) { should eq(:"OtherClass#knows") }
#     end

#   end

# end
