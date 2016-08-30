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
      post = Post.new(comments: [Comment.create])
      expect(Post.new(comments: [Comment.create])).to be_valid
    end

    it 'direct comments assignment should ignore validation' do
      post = Post.new(comments: [Comment.create])
      post.comments = []
      expect(post.reload.comments).to be_empty
    end

    it 'should not save on update_attributes if invalid' do
      post = Post.create(comments: [Comment.create])
      expect(post.update(comment_ids: [])).to be false
      post.comments
      # expect(Post.find(post.id).comments).not_to be_empty
      # expect(post.reload.comments).not_to be_empty
      expect(post.reload.comments).to be_present
    end
  end
end
