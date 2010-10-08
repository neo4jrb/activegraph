class Avator < Neo4j::Model
  property :icon
end

class Post < Neo4j::Model
  property :title
end

class Member < Neo4j::Model
  has_n(:posts).to(Post)
  has_n(:valid_posts).to(Post)

  has_one(:avatar).to(Avator)
  accepts_nested_attributes_for :avatar, :allow_destroy => true
  accepts_nested_attributes_for :posts
  accepts_nested_attributes_for :valid_posts, :reject_if => proc { |attributes| attributes[:title].blank? }

end