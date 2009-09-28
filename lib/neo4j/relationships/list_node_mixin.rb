module Neo4j::NodeMixin

  def list?(list_name)
    regexp = Regexp.new "_list_#{list_name}"
    relationships.both.find { |rel| regexp.match(rel.relationship_type.to_s) } != nil
  end

  def list(list_name, list_node = nil)
    if list_node
      list_id = "_list_#{list_name}_#{list_node.neo_node_id}"
      add_list_item_methods(list_id, list_name, list_node)
    else
      list_items = []
      lists(list_name) {|list_item| list_items << list_item}
      list_items[0]
    end
  end


  def lists(*list_names)
    list_names.collect! {|n| n.to_sym}
    
    relationships.both.inject({}) do |res, rel|
      rel_type = rel.relationship_type.to_s
      md = /_list_(\w*)_(\d*)/.match(rel_type)
      next res if md.nil?
      next res unless list_names.empty? || list_names.include?(md[1].to_sym)
      res[rel_type] = [md[1], Neo4j.load(md[2].to_i)]
      res
    end.each_pair do |rel_id, list_name_and_head_node|
      yield self.clone.add_list_item_methods(rel_id, list_name_and_head_node[0], list_name_and_head_node[1])
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
        next_node = relationships.outgoing(list_id).nodes.first
        return nil if next_node.nil?
        next_node.add_list_item_methods(list_id, list_name, head_node)
        next_node
      end

      define_method :next= do |new_next|
        # does it have a next pointer ?
        next_rel = relationships.outgoing(list_id).first
        # delete the relationship if exists
        next_rel.delete if (next_rel.nil?)
        relationships.outgoing(list_id) << new_next
        nil
      end

      define_method :prev do
        prev_node = relationships.incoming(list_id).nodes.first
        return nil if prev_node.nil?
        prev_node.add_list_item_methods(list_id, list_name, head_node)
        prev_node
      end

      define_method :prev= do |new_prev|
        # does it have a next pointer ?
        prev_rel = relationships.incoming(list_id).first
        # delete the relationship if exists
        prev_rel.delete if (prev_rel.nil?)
        relationships.outgoing(list_id) << new_prev
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