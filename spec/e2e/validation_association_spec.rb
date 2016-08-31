describe Neo4j::ActiveNode::Validations do
  before(:each) do
    stub_active_node_class('Comment')

    stub_active_node_class('Post') do
      has_many :out, :comments, type: :COMMENT

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
      expect(Post.new(comments: [Comment.create])).to be_valid
    end
  end

  #The below spec pass on active_record as is
  context 'active_record behaviour' do
    before :each do
      @post = Post.create(comments: [Comment.create])
    end
    it "comment= ignores validation" do
      @post.comments = []
      expect(@post.comments.size).to eq(0)
      expect(@post.comments.count).to eq(0)
      expect(Post.find(@post.id).comments.count).to eq(0)
    end

    it "update respects validation" do
      expect(@post.update(comments: [])).to be false
      expect(@post.comments.size).to eq(0)
      expect(@post.comments.count).to eq(1)
      expect(Post.find(@post.id).comments.count).to eq(1)
    end

    it 'comments= saves invalid object' do
      expect(Post.find(@post.id)).to be_valid
      @post.comments = []
      expect(Post.find(@post.id)).not_to be_valid
    end

    it 'update does not save invalid object' do
      expect(Post.find(@post.id)).to be_valid
      expect(@post.update(comments: [])).to be false
      expect(Post.find(@post.id)).to be_valid
    end
  end
end
