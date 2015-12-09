describe 'Node Wrapping' do
  before(:each) do
    clear_model_memory_caches

    stub_active_node_class('Post')

    stub_active_node_class('GitHub') do
      self.mapped_label_name = 'GitHub'
    end

    stub_active_node_class('StackOverflow') do
      self.mapped_label_name = 'StackOverflow'
    end


    stub_named_class('GitHubUser', GitHub) do
      self.mapped_label_name = 'User'
    end

    stub_named_class('GitHubAdmin', GitHubUser) do
      self.mapped_label_name = 'Admin'
    end

    stub_named_class('StackOverflowUser', StackOverflow) do
      self.mapped_label_name = 'User'
    end

    stub_const 'SomeOtherClass', Class.new
  end

  after do
    Post.delete_all
    GitHubUser.delete_all
    StackOverflowUser.delete_all
  end

  context 'A labeled exists' do
    let(:labels) { [] }
    let(:label_string) { labels.map { |label| ":`#{label}`" }.join }

    before do
      Neo4j::Session.query.create("(n#{label_string})").exec
    end

    let(:result) { Neo4j::Session.query.match("(n#{label_string})").pluck(:n).first }

    raw_node_class = (RUBY_PLATFORM =~ /java/) ? 'Java::OrgNeo4jKernelImplCore::NodeProxy' : '::Neo4j::Server::CypherNode'

    {
      %w(ExtraneousLabel) => raw_node_class,
      %w(Post) => 'Post',

      %w(ExtraneousLabel Post) => 'Post',

      %w(SomeOtherClass) => raw_node_class,
      %w(SomeOtherClass Post) => 'Post',

      %w(User GitHub) => 'GitHubUser',
      %w(User StackOverflow) => 'StackOverflowUser',
      %w(Admin User GitHub) => 'GitHubAdmin',
      %w(Admin GitHub) => 'GitHub',

      %w(Random GitHub) => 'GitHub',
      %w(Admin User StackOverflow) => 'StackOverflowUser',
      %w(Admin StackOverflow) => 'StackOverflow'

    }.each do |l, model_name|
      label_list = l.map { |lab| ":#{lab}" }.to_sentence
      context "labels #{label_list}" do
        let(:labels) { l }

        it "wraps the node with a #{model_name} object" do
          expect(result).to be_kind_of(model_name.constantize)
        end
      end
    end
  end
end


# classes User, Post
#  :User => User
#  :Post => Post
#  :Post:Submitted => :Post
#
# classes Person, User < Person, Post
#  :User:Person => User
#  :Person => Person
#  :Post => Post
#  :Post:Submitted => Post
#
# classes GitHub, StackOverflow, GitHubUser < GitHub, StackOverflowUser < StackOverflow, Post
#
#  :User:StackOverflow => StackOverflowUser
#  :User:GitHub => GitHubUser
#  :Admin:User:GitHub => GitHubUser
#  :User => fail
#  :GitHub => fail
#  :StackOverflow => fail
#  :Post => Post
#
