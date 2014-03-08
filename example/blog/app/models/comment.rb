class Comment
  include Neo4j::ActiveNode
  property :title
  property :text

  index :title
  has_one(:post).from(Post, :comments)
end