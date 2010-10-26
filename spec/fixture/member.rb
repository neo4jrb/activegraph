class Avatar < Neo4j::Model
  property :icon
end

class Post < Neo4j::Model
  property :title
end

class Member < Neo4j::Model
  has_n(:posts).to(Post)
  has_n(:valid_posts).to(Post)
  has_n(:valid_posts2).to(Post)

  has_one(:avatar).to(Avatar)

  has_one(:thing)

  accepts_nested_attributes_for :avatar, :allow_destroy => true
  accepts_nested_attributes_for :posts, :allow_destroy => true
  accepts_nested_attributes_for :valid_posts, :reject_if => proc { |attributes| attributes[:title].blank? }
  accepts_nested_attributes_for :valid_posts2, :reject_if => :reject_posts

  def reject_posts(attributed)
    attributed[:title].blank?
  end

end