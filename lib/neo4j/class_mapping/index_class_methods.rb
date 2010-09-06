module Neo4j
  module IndexClassMethods
    def index(field)
      key = "#{root_class}::#{field}"
      puts "add index #{key}"
      Neo4j::Node.index(key)
    end

    def find(field, query)
      key = "#{root_class}::#{field}"
      puts "search index #{key}"
      Neo4j.find(key, query)
    end
  end
end