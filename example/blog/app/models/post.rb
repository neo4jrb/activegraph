class Post
  include Neo4j::ActiveNode
  property :title
  property :text, default: 'bla bla bla'
  property :score, type: Integer, default: 0  # See ActiveAttr gem for arguments

  validates :title, presence: true
  validates :score, numericality: {only_integer: true}

  index :title

  before_save do
    self.score = score * 100
  end

  # Example on generating ID from a property
  # Here we want to make the title the primary key
  # id_property :title_id, on: :title_to_url

  # def title_to_url
  #   self.title.urlize # uses https://github.com/cheef/string-urlize gem
  # end

  # Relationship name is defined in PostComment
  # Generates a comments accessor methods for navigating/querying 'stated_opinions' outgoing relationships
  has_many :out, :comments, rel_class: PostComment

  # or if you don't need to use ActiveRel models:
  # has_many :out, :comments
end
