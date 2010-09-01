module Neo4j::RelClassMethods


  # Contains information of all relationships, name, type, and multiplicity
  #
  # :api: private
  def decl_relationships # :nodoc:
    self::DECL_RELATIONSHIPS
  end


  # Specifies a relationship between two node classes.
  # Generates assignment and accessor methods for the given relationship
  #
  # ==== Example
  #
  #   class FileNode
  #      include Ne4j::NodeMixin
  #      has_one(:folder)
  #   end
  #
  #   file = FileNode.new
  #   file.folder = Neo4j::Node.new
  #   file.folder # => the node above
  #
  # ==== Returns
  #
  # Neo4j::Relationships::DeclRelationshipDsl
  #
  def has_one(rel_type, params = {})
    clazz = self
    module_eval(%Q{def #{rel_type}=(value)
                    dsl = #{clazz}.decl_relationships[:'#{rel_type.to_s}']
                    r = Neo4j::Relationships::HasN.new(self, dsl)
                    r.each {|n| n.del} # delete previous relationships, only one can exist
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
  # Generates assignment and accessor methods for the given relationship.
  #
  # ==== Example
  #
  #   class FolderNode
  #      include Ne4j::NodeMixin
  #      has_n(:files)
  #   end
  #
  #   folder = FolderNode.new
  #   folder.files << Neo4j::Node.new << Neo4j::Node.new
  #   folder.files.inject {...}
  #
  # ==== Returns
  #
  # Neo4j::Relationships::DeclRelationshipDsl
  #
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
  # ==== Example
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

  def indexer # :nodoc:
    Neo4j::Indexer.instance(root_class) # create an indexer that search for nodes (and not relationships)
  end

end
