class Comment
  include Neo4j::ActiveNode
  property :title
  property :text

  index :title
  has_one :in, :post, rel_class: PostComment

  # or if PostComment is not needed
  # has_one :in, :post
end
