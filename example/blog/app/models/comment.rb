class Comment
  include Neo4j::ActiveNode
  property :title
  property :text

  index :title
  has_one :in, :post, origin: :comments, rel_class: PostComment

end
