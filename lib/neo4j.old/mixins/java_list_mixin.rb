module Neo4j::JavaListMixin

  # --------------------------------------------------------------------------
  # List methods
  #


  # Returns true if this nodes belongs to a list of the given name
  #
  def list?(list_name)
    regexp = Regexp.new "_list_#{list_name}"
    rels.both.find { |rel| regexp.match(rel.relationship_type.to_s) } != nil
  end

  # Returns one or more list of the given list_name and list_node.
  # If the optional list_node parameter is given the specific list belonging to that list node will be returned (or nil)
  # If only the list_name parameter is given the first list matching the given list_name will be returned.
  # (There might be several list of the same name but from different list nodes.)
  #
  # ==== Returns
  #
  # The node but with the extra instance methods
  # * next - the next node in the list
  # * prev - the previous node in the list
  # * head - the head node (the node that has the has_list method)
  # * size (if the size optional parameter is given in the has_list class method)
  #
  # ==== Example
  #  class Foo
  #    include Neo4j::NodeMixin
  #    has_list :baar
  #  end
  #
  #  f = Foo.new
  #  n1 = Neo4j::Node.new
  #  n2 = Neo4j::Node.new
  #  f.baar << n1 << n2
  #
  #  n2.list(:baar).next # => n1
  #  n2.list(:baar).prev # => f
  #  n2.list(:baar).head # => f
  #
  def list(list_name, list_node = nil)
    if list_node
      list_id = "_list_#{list_name}_#{list_node.neo_id}"
      add_list_item_methods(list_id, list_name, list_node)
    else
      list_items = []
      lists(list_name) {|list_item| list_items << list_item}
      list_items[0]
    end
  end


  # Returns an array of lists with the given names that this nodes belongs to.
  # Expects a block to yield for each found list
  # That block will be given one parameter - the node with the extra method (see #list method)
  #
  def lists(*list_names)
    list_names.collect! {|n| n.to_sym}

    rels.both.inject({}) do |res, rel|
      rel_type = rel.relationship_type.to_s
      md = /_list_(\w*)_(\d*)/.match(rel_type)
      next res if md.nil?
      next res unless list_names.empty? || list_names.include?(md[1].to_sym)
      res[rel_type] = [md[1], Neo4j.load_node(md[2])]
      res
    end.each_pair do |rel_id, list_name_and_head_node|
      yield self.add_list_item_methods(rel_id, list_name_and_head_node[0], list_name_and_head_node[1]) # clone ?
    end
  end


  def add_list_item_methods(list_id, list_name, head_node) #:no_doc:
    mod = Module.new do
      define_method :head do
        head_node
      end

      define_method :size do
        head_node["_#{list_name}_size"] || 0
      end

      define_method :size= do |new_size|
        head_node["_#{list_name}_size"] = new_size
      end

      define_method :next do
        next_node = rels.outgoing(list_id).nodes.first
        return nil if next_node.nil?
        next_node.add_list_item_methods(list_id, list_name, head_node)
        next_node
      end

      define_method :next= do |new_next|
        # does it have a next pointer ?
        next_rel = rels.outgoing(list_id).first
        # delete the relationship if exists
        next_rel.delete if (next_rel.nil?)
        rels.outgoing(list_id) << new_next unless new_next.nil?
        nil
      end

      define_method :prev do
        prev_node = rels.incoming(list_id).nodes.first
        return nil if prev_node.nil?
        prev_node.add_list_item_methods(list_id, list_name, head_node)
        prev_node
      end

      define_method :prev= do |new_prev|
        # does it have a next pointer ?
        prev_rel = rels.incoming(list_id).first
        # delete the relationship if exists
        prev_rel.delete if (prev_rel.nil?)
        rels.outgoing(list_id) << new_prev unless new_prev.nil?
        nil
      end
    end

    self.extend mod
  end

  def add_list_head_methods(list_name) # :nodoc:
    prop_name = "_#{list_name}_size".to_sym
    mod = Module.new do
      define_method :size do
        self[prop_name] || 0
      end

      define_method :size= do |new_size|
        self[prop_name]=new_size
      end
    end
    self.extend mod
  end
  
end