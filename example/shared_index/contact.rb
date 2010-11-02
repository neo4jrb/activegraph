SIZE = 10
FRIEND_SIZE = 3


class User
  include Neo4j::NodeMixin
  property :first_name
  property :last_name
end

class Contact
  include Neo4j::NodeMixin
  property :name
  property :city

  has_one(:user).from(User, :contact)
  has_n(:users).to(User)


  index :name
  index :city

  def to_s
    "Contact id: #{neo_id} #{name} #{city}"
  end
end

class User
  property :user_id
  has_one(:contact).to(Contact)
  has_n(:contacts).from(Contact, :users)

  def init_on_create(*args)
    super
    name, user_id, city = args
    self.user_id = user_id
    self.contact = Contact.new :name => name, :city => city
  end

  def to_s
    "User id: #{user_id} #{contact.name}"
  end

  index :user_id, :via => :contacts
  index :user_id
end
