require 'spec_helper'

describe 'Node Wrapping' do
  module NodeWrappingSpec
    class Post
      include Neo4j::ActiveNode
    end

    class GitHub
      include Neo4j::ActiveNode
      self.mapped_label_name = 'GitHub'
    end

    class StackOverflow
      include Neo4j::ActiveNode
      self.mapped_label_name = 'StackOverflow'
    end

    class GitHubUser < GitHub
      self.mapped_label_name = 'User'
    end

    class GitHubAdmin < GitHubUser
      self.mapped_label_name = 'Admin'
    end

    class StackOverflowUser < StackOverflow
      self.mapped_label_name = 'User'
    end
  end


  after do
    NodeWrappingSpec::Post.delete_all
    NodeWrappingSpec::GitHubUser.delete_all
    NodeWrappingSpec::StackOverflowUser.delete_all
  end

  context 'A labeled exists' do
    let(:labels) { [] }
    let(:label_string) { labels.map { |label| ":`#{label}`" }.join }

    before do
      Neo4j::Session.query.create("(n#{label_string})").exec
    end

    let(:result) { Neo4j::Session.query.match("(n#{label_string})").pluck(:n).first }

    {

      %w(NodeWrappingSpec::Post) => NodeWrappingSpec::Post,
      %w(User GitHub) => NodeWrappingSpec::GitHubUser,
      %w(User StackOverflow) => NodeWrappingSpec::StackOverflowUser,
      %w(Admin User GitHub) => NodeWrappingSpec::GitHubAdmin,
      %w(Admin GitHub) => NodeWrappingSpec::GitHub,

      %w(Random GitHub) => NodeWrappingSpec::GitHub,
      %w(Admin User StackOverflow) => NodeWrappingSpec::StackOverflowUser,
      %w(Admin StackOverflow) => NodeWrappingSpec::StackOverflow

    }.each do |l, model|
      label_list = l.map { |lab| ":#{lab}" }.to_sentence
      context "labels #{label_list}" do
        let(:labels) { l }

        it "wraps the node with a #{model} object" do
          expect(result).to be_kind_of(model)
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
