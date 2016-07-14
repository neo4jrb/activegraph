module Neo4j
  module Migrations
    module Helpers
      module Relationships
        extend ActiveSupport::Concern

        def change_relation_style(relationships, old_style, new_style, params = {})
          relationships.each do |rel|
            relabel_relation(relationship_style(rel, old_style), relationship_style(rel, new_style), params)
          end
        end

        def relabel_relation(old_name, new_name, params = {})
          relation_query = match_relation(old_name, params)

          count = count_relations(relation_query)
          output "Indexing #{count} #{old_name}s into #{new_name}..."
          while count > 0
            relation_query.create("(a)-[r2:`#{new_name}`]->(b)").set('r2 = r').with(:r).limit(1000).delete(:r).exec
            count = count_relations(relation_query)
            if count > 0
              output "... #{count} #{style(relationship, :old)}'s left to go.."
            end
          end
        end

        private

        def match_relation(label, params = {})
          from = params[:from] ? "(a:`#{params[:from]}`)" : '(a)'
          to = params[:to] ? "(a:`#{params[:to]}`)" : '(b)'
          relation = arrow_cypher(label, params[:direction])

          query.match("#{from}#{relation}#{to}")
        end

        def arrow_cypher(label, direction)
          case direction
          when :in
            "<-[r:`#{label}`]-"
          when :both
            "<-[r:`#{label}`]->"
          else
            "-[r:`#{label}`]->"
          end
        end

        def count_relations(query)
          query.pluck('COUNT(r)').first
        end

        def relationship_style(relationship, format)
          case format
          when 'lower_hashtag' then "##{relationship.downcase}"
          when 'lower'         then "#{relationship.downcase}"
          when 'upper'         then "#{relationship.upcase}"
          else
            fail("Invalid relationship type style `#{format}`.")
          end
        end
      end
    end
  end
end
