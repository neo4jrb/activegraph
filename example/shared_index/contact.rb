class User
  include Neo4j::NodeMixin
  property :first_name
  property :last_name
end

class Contact
  include Neo4j::NodeMixin
  property :first_name
  property :last_name
  property :city

  has_one(:user).from(User, :contact)
  has_n(:users).to(User)


  index :first_name
  index :last_name
  index :city

  def to_s
    "Contact id: #{neo_id} #{first_name} #{city}"
  end
end

class User
  property :user_id
  has_one(:contact).to(Contact)
  has_n(:contacts).from(Contact, :users)

  def init_on_create(*args)
    super
    first_name, last_name, city = args
    self.user_id = neo_id
    self.contact = Contact.new :first_name => first_name, :last_name => last_name, :city => city
  end

  def to_s
    "User id: #{user_id} #{contact.first_name} #{contact.last_name}"
  end

  index :user_id, :via => :contacts
end
