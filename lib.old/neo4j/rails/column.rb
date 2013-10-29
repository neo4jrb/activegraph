#
# This is a way to wrap model attributes as Active Record-like column objects, providing a name and type for the column. 
# This helps when using view generators, such as twitter-bootstrap-rails. 
#


module Neo4j
  module Rails
    
    class Column
      
      attr_reader :name, :type, :index, :converter
      
      def initialize(args)
           raise ArgumentError, "Column must passed a :name" if args[:name].nil?
           args[:type] ||= "String" # default the type to String. 
           args.each do |k,v|
             instance_variable_set("@#{k}", v.to_s) unless v.nil?
           end
      end
      
    end 
    
  end #rails
end #neo4j
    