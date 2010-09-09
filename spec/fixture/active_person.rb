class ActivePerson < Neo4j::ActiveModel
  validates_presence_of :name
  property :name, :age
  alias_method :_orig_name=, :name=

  def save
    @previously_changed = changes
    @changed_attributes.clear
  end
end