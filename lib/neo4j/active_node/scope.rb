require 'active_support/per_thread_registry'

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
      #   Person.scope :level, ->(num) { where(level_num: num)}
      #
      # @example Argument as a cypher identifier
      #   class Person
      #     include Neo4j::ActiveNode
      #     property :name
      #     property :score
      #     has_many :out, :friends, model_class: self
      #     scope :great_students, ->(identifier) { where("#{identifier}.score > 41") }
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

      def has_scope?(name)
        _scope.has_key?(name.to_sym)
      end

      def _scope
        @_scope ||= {}
      end

      def _call_scope_context(eval_context, query_params, proc)
        if proc.arity == 1
          eval_context.instance_exec(query_params, &proc)
        else
          eval_context.instance_exec(&proc)
        end
      end


      def current_scope #:nodoc:
        ScopeRegistry.value_for(:current_scope, base_class.to_s)
      end

      def current_scope=(scope) #:nodoc:
        ScopeRegistry.set_value_for(:current_scope, base_class.to_s, scope)
      end


      def all
        if current_scope
          current_scope.clone
        else
          self.as(:n)
        end
      end

    end

    class ScopeEvalContext
      def initialize(target, query_proxy)
        @query_proxy = query_proxy
        @target = target
      end

      Neo4j::ActiveNode::Query::QueryProxy::METHODS.each do |method|
        module_eval(%Q{
            def #{method}(params={})
              @target.all.scoping do
                (@query_proxy || @target).#{method}(params)
              end
            end}, __FILE__, __LINE__)
      end
    end


    # Stolen from ActiveRecord
    # https://github.com/rails/rails/blob/08754f12e65a9ec79633a605e986d0f1ffa4b251/activerecord/lib/active_record/scoping.rb#L57
    class ScopeRegistry # :nodoc:
      extend ActiveSupport::PerThreadRegistry

      VALID_SCOPE_TYPES = [:current_scope, :ignore_default_scope]

      def initialize
        @registry = Hash.new { |hash, key| hash[key] = {} }
      end

      # Obtains the value for a given +scope_name+ and +variable_name+.
      def value_for(scope_type, variable_name)
        raise_invalid_scope_type!(scope_type)
        @registry[scope_type][variable_name]
      end

      # Sets the +value+ for a given +scope_type+ and +variable_name+.
      def set_value_for(scope_type, variable_name, value)
        raise_invalid_scope_type!(scope_type)
        @registry[scope_type][variable_name] = value
      end

      private

      def raise_invalid_scope_type!(scope_type)
        if !VALID_SCOPE_TYPES.include?(scope_type)
          raise ArgumentError, "Invalid scope type '#{scope_type}' sent to the registry. Scope types must be included in VALID_SCOPE_TYPES"
        end
      end
    end

  end
end
