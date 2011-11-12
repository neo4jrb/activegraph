module Neo4j::HasList
  module ClassMethods
      def has_list(name, params = {})
        module_eval(%Q{
                def #{name}
                  Neo4j::HasList::Mapping.new(self.class, self, '#{name}')
                end}, __FILE__, __LINE__)
      end
  end
end

