describe Neo4j::ActiveNode::Validations do
  before(:each) do
    stub_active_node_class('Comment')

    stub_active_node_class('Post') do
      has_many :out, :comments, type: :COMMENT

      validates :comments, presence: true
    end
  end

  context 'validating presence' do
    it 'should not be valid without comments' do
      expect(Post.create.valid?).to be false
    end

    it 'should be valid with comments' do
      expect(Post.new(comments: [Comment.create])).to be_valid
    end
  end
end
