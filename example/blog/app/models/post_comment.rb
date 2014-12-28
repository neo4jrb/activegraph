class PostComment
  include Neo4j::ActiveRel
  # would accept :any instead of model constant
  from_class Post
  to_class Comment

  # or
  # start_class Post
  # end_class Comment

  type 'stated_opinions'

  # automatically adds timestamps
  property :created_at
end
