module Neo4j::Rails
  # Allows accepting id for association objects. For example
  # class Book < Neo4j::Model
  #   has_one(:author).to(Author)
  #   accepts_id_for :author
  # end
  #
  # This would add a author_id getter and setter on Book. You could use
  # book = Book.new(:name => 'Graph DBs', :author_id => 11)
  # book.author_id # 11
  # book.author_id = 13
  # TODO: Support for has_n associations
  module AcceptId
    extend ActiveSupport::Concern

    module ClassMethods
      # Adds association_id getter and setter for one or more has_one associations
      #
      # @example
      # class Book < Neo4j::Model
      #   has_one(:author).to(Author)
      #   has_one(:publisher).to(Publisher)
      #   accepts_id_for :author, :publisher
      # end
      def accepts_id_for(*association_names)
        association_names.each do |association_name|
          define_association_id_getter(association_name)
          define_association_id_setter(association_name)
          accepts_id_associations << association_name
        end
      end

      # Check if model accepsts id for its association
      # @example
      # Book.accepts_id_for?(:author) => true
      # Book.accepts_id_for?(:genre) => false
      def accepts_id_for?(association_name)
        accepts_id_associations.include?(association_name)
      end

      def accepts_id_associations #nodoc
        @accepts_id_associations ||= []
      end

      protected
      def define_association_id_getter(association_name)
        class_eval %Q{
          def #{association_name}_id
            association_object = self.#{association_name}
            association_object.present? ? association_object.id : nil
          end
        }, __FILE__, __LINE__
      end

      def define_association_id_setter(association_name)
        class_eval %Q{
          def #{association_name}_id=(id)
            relation_target_class = self.class._decl_rels[:#{association_name}].target_class
            association_class =  relation_target_class <= self.class ?  Neo4j::Model : relation_target_class
            self.#{association_name} = id.present? ? association_class.find(id) : nil
          end
        }, __FILE__, __LINE__
      end
    end
  end
end