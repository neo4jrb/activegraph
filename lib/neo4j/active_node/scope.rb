module Neo4j::ActiveNode
  module Scope
    extend ActiveSupport::Concern

    module ClassMethods

      # Similar to ActiveRecord scope
      #
      # @example without argument
      #   class Person
      #     include Neo4j::ActiveNode
      #     property :name
      #     property :score
      #     has_many :out, :friends, model_class: self
      #     scope :top_students, -> { where(score: 42)}") }
      #   end
      #   Person.top_students.to_a
      #   a_person.friends.top_students.to_a
      #   a_person.friends.friends.top_students.to_a
      #   a_person.friends.top_students.friends.to_a
      #
      # @example Argument for scopes
      #   Person.scope :level, -> (num) { where(level_num: num)}
      #
      # @example Argument as a cypher identifier
      #   class Person
      #     include Neo4j::ActiveNode
      #     property :name
      #     property :score
      #     has_many :out, :friends, model_class: self
      #     scope :great_students, -> (identifier) { where("#{identifier}.score > 41") }
      #   end
      #   Person.as(:all_people).great_students(:all_people).to_a
      #
      # @see http://guides.rubyonrails.org/active_record_querying.html#scopes
      def scope(name, proc)
        _scope[name.to_sym] = proc

        module_eval(%Q{
          def #{name}(query_params=nil, _=nil, query_proxy=nil)
            eval_context = ScopeEvalContext.new(self, query_proxy || self.class.query_proxy)
            proc = self.class._scope[:"#{name}"]
            self.class._call_scope_context(eval_context, query_params, proc)
          end
        }, __FILE__, __LINE__)

        instance_eval(%Q{
          def #{name}(query_params=nil, _=nil, query_proxy=nil)
            eval_context = ScopeEvalContext.new(self, query_proxy || self.query_proxy)
            proc = _scope[:"#{name}"]
            _call_scope_context(eval_context, query_params, proc)
          end
        }, __FILE__, __LINE__)
      end



      def _scope
        @_scope ||= {}
      end

      def _call_scope_context(eval_context, query_params, proc)
        if proc.arity == 1
          eval_context.instance_exec(query_params,&proc)
        else
          eval_context.instance_exec(&proc)
        end
      end


    end

    class ScopeEvalContext
      def initialize(target, query_proxy)
        @query_proxy = query_proxy
        @target = target
      end


      def where(params={})
        (@query_proxy || @target).where(params)
      end
    end
  end
end
