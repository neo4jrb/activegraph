class ActivePerson < Neo4j::ActiveModel
  validates_presence_of :name
  property :name, :age
#  define_attribute_methods [:name]
#  define_attribute_methods [:age]

  alias_method :_orig_name=, :name=

  def name=(val)
    old = self.name
    name_will_change! unless val == old
    self._orig_name=val
  end


  def save
    @previously_changed = changes
    @changed_attributes.clear
  end
end