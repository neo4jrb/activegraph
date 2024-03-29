module ActiveGraph
  module Node
    module Query
      module QueryProxyMethodsOfMassUpdating
        # Updates some attributes of a group of nodes within a QP chain.
        # The optional argument makes sense only of `updates` is a string.
        # @param [Hash,String] updates An hash or a string of parameters to be updated.
        # @param [Hash] params An hash of parameters for the update string. It's ignored if `updates` is an Hash.
        def update_all(updates, params = {})
          # Move this to Node module?
          update_all_with_query(identity, updates, params)
        end

        # Updates some attributes of a group of relationships within a QP chain.
        # The optional argument makes sense only of `updates` is a string.
        # @param [Hash,String] updates An hash or a string of parameters to be updated.
        # @param [Hash] params An hash of parameters for the update string. It's ignored if `updates` is an Hash.
        def update_all_rels(updates, params = {})
          fail 'Cannot update rels without a relationship variable.' unless @rel_var
          update_all_with_query(@rel_var, updates, params)
        end

        # Deletes a group of nodes and relationships within a QP chain. When identifier is omitted, it will remove the last link in the chain.
        # The optional argument must be a node identifier. A relationship identifier will result in a Cypher Error
        # @param identifier [String,Symbol] the optional identifier of the link in the chain to delete.
        def delete_all(identifier = nil)
          query_with_target(identifier) do |target|
            begin
              self.query.with(target).optional_match("(#{target})-[#{target}_rel]-()").delete("#{target}, #{target}_rel").exec
            rescue Neo4j::Driver::Exceptions::ClientException # <=- Seems hacky
              self.query.delete(target).exec
            end
            clear_source_object_cache
          end
        end

        # Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.
        def delete(node)
          self.match_to(node).query.delete(rel_var).exec
          clear_source_object_cache
        end

        # Deletes the relationships between all nodes for the last step in the QueryProxy chain.  Executed in the database, callbacks will not be run.
        def delete_all_rels
          return unless start_object && start_object._persisted_obj
          self.query.delete(rel_var).exec
        end

        # Deletes the relationships between all nodes for the last step in the QueryProxy chain and replaces them with relationships to the given nodes.
        # Executed in the database, callbacks will not be run.
        def replace_with(node_or_nodes)
          node_or_nodes = Array(node_or_nodes).map { |arg| arg.is_a?(ActiveGraph::Node) ? arg : @model.find(arg) }
          original_ids = self.pluck(:id)
          ActiveGraph::Base.lock_node(start_object) unless start_object.new_record?
          delete_rels_for_nodes(original_ids, node_or_nodes.collect(&:id))
          add_rels(node_or_nodes, original_ids)
        end

        def add_rels(node_or_nodes, original_ids)
          node_or_nodes.map do |obj|
            obj if original_ids.include?(obj.id) || _create_relation_or_defer(obj)
          end.compact
        end

        def delete_rels_for_nodes(original_ids, new_ids)
          ids = original_ids.select { |id| !new_ids.include?(id) }
          return unless ids.present?
          if association.dependent
            start_object.public_send("dependent_#{association.dependent}_callback", association, ids)
          else
            self.where(id: ids).delete_all_rels
          end
        end

        # Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.
        def destroy(node)
          self.rels_to(node).map!(&:destroy)
          clear_source_object_cache
        end

        private

        def update_all_with_query(var_name, updates, params)
          query = all.query

          case updates
          when Hash then query.set(var_name => updates).pluck("count(#{var_name})").first
          when String then query.set(updates).params(params).pluck("count(#{var_name})").first
          else
            fail ArgumentError, "Invalid parameter type #{updates.class} for `updates`."
          end
        end

        def clear_source_object_cache
          self.source_object.clear_association_cache if self.source_object.respond_to?(:clear_association_cache)
        end
      end
    end
  end
end
