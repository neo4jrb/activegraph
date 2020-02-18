describe ActiveGraph::Node::Validations do
  before(:each) do
    stub_node_class('Comment')

    stub_node_class('Post') do
      property :name, type: String
      has_many :out, :comments, type: :COMMENT

      validates :name, presence: true
      validates :comments, presence: true
    end
  end

  context 'validating presence' do
    it 'new object should not be valid without comments' do
      expect(Post.new({})).not_to be_valid
    end

    it 'should not be valid without comments' do
      expect(Post.create).not_to be_valid
    end

    it 'should be valid with comments' do
      expect(Post.new(name: 'abc', comments: [Comment.create])).to be_valid
    end
  end

  # The below spec pass on active_record as is
  context 'active_record behaviour' do
    let(:post) { Post.create!(name: 'abc', comments: [Comment.create]) }

    it 'comment= ignores validation' do
      post.comments = []
      expect(post.comments.size).to eq(0)
      expect(post.comments.count).to eq(0)
      expect(Post.find(post.id).comments.count).to eq(0)
    end

    it 'update respects validation' do
      expect(post.update(comments: [])).to be false
      expect(post.comments.size).to eq(0)
      expect(post.comments.count).to eq(1)
      expect(Post.find(post.id).comments.count).to eq(1)
    end

    it 'comments= saves invalid object' do
      expect(Post.find(post.id)).to be_valid
      post.comments = []
      expect(Post.find(post.id)).to be_invalid
    end

    it 'update does not save invalid object' do
      expect(Post.find(post.id)).to be_valid
      expect(post.update(comments: [])).to be false
      expect(Post.find(post.id)).to be_valid
    end

    it 'should not save valid association if property is invalid' do
      expect(post.update(name: nil, comments: [Comment.create, Comment.create])).to be false
      expect(Post.find(post.id).comments.count).to eq(1)
    end
  end
end
