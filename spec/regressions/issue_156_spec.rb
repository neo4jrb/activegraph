require 'spec_helper'

module Regressions

  describe "Redundantly setting both halves of a has_one rel causes issues", :type => :integration do

#    If two posts are related:
    class Post < Neo4j::Rails::Model
    end

    class Post
      has_one(:older_post).to(Post)
      has_one(:newer_post).from(Post, :older_post)
    end

    it "can have two post related" do
      p1 = Post.new
      p2 = Post.new

      p1.older_post = p2
      p2.older_post = p1

      p1.save
      p2.save
      #Two rels are created:

      p1.older_post.should == p2
      p2.newer_post.should == p1

      p1.newer_post.should == p2
      p2.older_post.should == p1

      p1 = Post.load_entity(p1.id)
      p2 = Post.load_entity(p2.id)

      p1.older_post.should == p2
      p2.newer_post.should == p1

      p1.newer_post.should == p2
      p2.older_post.should == p1

    end
  end
end
