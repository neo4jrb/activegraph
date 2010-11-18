module Neo4j::Mapping
  module ClassMethods
    module List
      def has_list(name, params = {})
        module_eval(%Q{
                def #{name}
                  Neo4j::Mapping::HasList.new(self, '#{name}')
                end}, __FILE__, __LINE__)
      end
    end
  end
end

