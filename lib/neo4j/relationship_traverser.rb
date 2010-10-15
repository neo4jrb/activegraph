module Neo4j

  class RelationshipTraverser
    include Enumerable
    include ToJava

    def initialize(node, types, dir)
      @node = node
      if types.size > 1
        @types = types.inject([]) { |result, type| result << type_to_java(type) }.to_java(:'org.neo4j.graphdb.RelationshipType')
      elsif types.size == 1
        @type = type_to_java(types[0])
      end

      @dir = dir_to_java(dir)
    end

    def to_s
      if @type
        "#{self.class} [type: #{@type} dir:#{@dir}]"
      elsif @types
        "#{self.class} [types: #{@types.join(',')} dir:#{@dir}]"
      else
        "#{self.class} [types: ANY dir:#{@dir}]"
      end
    end

    def each
      iterator.each {|i| yield i.wrapper}
    end

    def iterator
      if @types
        @node.get_relationships(@types).iterator
      elsif @type
        @node.get_relationships(@type, @dir).iterator
      else
        @node.get_relationships(@dir).iterator
      end
    end

    def size
      [*self].size
    end

    def both
      @dir = dir_to_java(:both)
      self
    end

    def incoming
      raise "Not allowed calling incoming when finding several relationships types" if @types
      @dir = dir_to_java(:incoming)
      self
    end

    def outgoing
      raise "Not allowed calling outgoing when finding several relationships types" if @types
      @dir = dir_to_java(:outgoing)
      self
    end

  end
end