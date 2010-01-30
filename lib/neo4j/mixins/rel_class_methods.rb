module Neo4j::RelClassMethods


  # Contains information of all relationships, name, type, and multiplicity
  #
  # :api: private
  def decl_relationships # :nodoc:
    self::DECL_RELATIONSHIPS
  end


  # Specifies a relationship between two node classes.
  #
  # ==== Example
  #   class Order
  #      include Neo4j::NodeMixin
  #      has_one(:customer).to(Customer)
  #   end
  #
  # :api: public
  def has_one(rel_type, params = {})
    clazz = self
    module_eval(%Q{def #{rel_type}=(value)
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    r = Neo4j::Relationships::HasN.new(self, dsl)
                    r << value
                    r
                end},  __FILE__, __LINE__)

    module_eval(%Q{def #{rel_type}
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    r = Neo4j::Relationships::HasN.new(self, dsl)
                    [*r][0]
                end},  __FILE__, __LINE__)

    module_eval(%Q{
                def #{rel_type}_rel
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    r = Neo4j::Relationships::HasN.new(self, dsl).rels
                    [*r][0]
      end}, __FILE__, __LINE__)

    decl_relationships[rel_type.to_sym] = Neo4j::Relationships::DeclRelationshipDsl.new(rel_type, params)
  end


  # Specifies a relationship between two node classes.
  #
  # ==== Example
  #   class Order
  #      include Neo4j::NodeMixin
  #      has_n(:order_lines).to(Product).relationship(OrderLine)
  #   end
  #
  # :api: public
  def has_n(rel_type, params = {})
    clazz = self
    module_eval(%Q{
                def #{rel_type}(&block)
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    Neo4j::Relationships::HasN.new(self, dsl, &block)
                end},  __FILE__, __LINE__)

    module_eval(%Q{
                def #{rel_type}_rels
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    Neo4j::Relationships::HasN.new(self, dsl).rels
      end}, __FILE__, __LINE__)

    decl_relationships[rel_type.to_sym] = Neo4j::Relationships::DeclRelationshipDsl.new(rel_type, params)
  end


  # Specifies a relationship to a linked list of nodes.
  # Each list item class may (but not necessarily  use the belongs_to_list
  # in order to specify which ruby class should be loaded when a list item is loaded.
  #
  # Example
  #
  #  class Company
  #    include Neo4j::NodeMixin
  #    has_list :employees
  #  end
  #
  #  company = Company.new
  #  company.employees << employee1 << employee2
  #
  #  # prints first employee2 and then employee1
  #  company.employees.each {|employee| puts employee.name}
  #
  # ===== Size Counter
  # If the optional parameter :size is given then the list will contain a size counter.
  #
  # Example
  #
  #  class Company
  #    include Neo4j::NodeMixin
  #    has_list :employees, :counter => true
  #  end
  #
  #  company = Company.new
  #  company.employees << employee1 << employee2
  #  company.employees.size # => 2
  #
  # ==== Deleted List Items
  #
  # The list will be updated if an item is deleted in a list.
  # Example:
  #
  #  company = Company.new
  #  company.employees << employee1 << employee2 << employee3
  #  company.employees.size # => 3
  #
  #  employee2.del
  #
  #  [*company.employees] # => [employee1, employee3]
  #  company.employees.size # => 2
  #
  # ===== List Items Memberships
  #
  #  For deciding which lists a node belongs to see the Neo4j::NodeMixin#list method
  #
  # :api: public
  def has_list(rel_type, params = {})
    clazz = self
    #(self.kind_of?(Module))? self : self.class
    module_eval(%Q{
                def #{rel_type}(&block)
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    Neo4j::Relationships::HasList.new(self, dsl, &block)
                end},  __FILE__, __LINE__)
    Neo4j.event_handler.add Neo4j::Relationships::HasList
    decl_relationships[rel_type.to_sym] = Neo4j::Relationships::DeclRelationshipDsl.new(rel_type, params)
  end


  # Can be used together with the has_list to specify the ruby class of a list item.
  #
  # :api: public
  def belongs_to_list(rel_type, params = {})
    decl_relationships[rel_type] = Neo4j::Relationships::DeclRelationshipDsl.new(rel_type, params)
  end


  # Finds all nodes of this type (and ancestors of this type) having
  # the specified property values.
  # See the lucene module for more information how to do a query.
  #
  # ==== Example
  #   MyNode.find(:name => 'foo', :company => 'bar')
  #
  # Or using a DSL query (experimental)
  #   MyNode.find{(name == 'foo') & (company == 'bar')}
  #
  # ==== Returns
  # Neo4j::SearchResult
  #
  # :api: public
  def find(query=nil, &block)
    self.indexer.find(query, block)
  end


  # Creates a new value object class (a Struct) representing this class.
  #
  # The struct will have the Ruby on Rails method: model_name and
  # new_record? so that it can be used for restful routing.
  #
  # @api private
  def create_value_class # :nodoc:
    # the name of the class we want to create
    name = "#{self.to_s}ValueObject".gsub("::", '_')

    # remove previous class if exists
    Neo4j.instance_eval do
      remove_const name
    end if Neo4j.const_defined?(name)

    # get the properties we want in the new class
    props = self.properties_info.keys.map{|k| ":#{k}"}.join(',')
    Neo4j.module_eval %Q[class #{name} < Struct.new(#{props}); end]

    # get reference to the new class
    clazz = Neo4j.const_get(name)

    # make it more Ruby on Rails friendly - try adding model_name method
    if self.respond_to?(:model_name)
      model = self.model_name.clone
      (
      class << clazz;
        self;
      end).instance_eval do
        define_method(:model_name) {model}
      end
    end

    # by calling the _update method we change the state of the struct
    # so that new_record returns false - Ruby on Rails
    clazz.instance_eval do
      define_method(:_update) do |hash|
        @_updated = true
        hash.each_pair {|key, value| self[key.to_sym] = value if members.include?(key.to_s) }
      end
      define_method(:new_record?) { ! defined?(@_updated) }
    end

    clazz
  end

end
