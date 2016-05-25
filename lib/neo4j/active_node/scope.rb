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
      #     has_many :out, :friends, type: :has_friend, model_class: self
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
      #     has_many :out, :friends, type: :has_friend, model_class: self
      #     scope :great_students, ->(identifier) { where("#{identifier}.score > 41") }
      #   end
      #   Person.as(:all_people).great_students(:all_people).to_a
      #
      # @see http://guides.rubyonrails.org/active_record_querying.html#scopes
      def scope(name, proc)
        scopes[name.to_sym] = proc

        klass = class << self; self; end
        klass.instance_eval do
          define_method(name) do |query_params = nil, _ = nil|
            eval_context = ScopeEvalContext.new(self, current_scope || self.query_proxy)
            proc = full_scopes[name.to_sym]
            _call_scope_context(eval_context, query_params, proc)
          end
        end
      end

      # rubocop:disable Style/PredicateName
      def has_scope?(name)
        ActiveSupport::Deprecation.warn 'has_scope? is deprecated and may be removed from future releases, use scope? instead.', caller

        scope?(name)
      end
      # rubocop:enable Style/PredicateName

      def scope?(name)
        full_scopes.key?(name.to_sym)
      end

      def scopes
        @scopes ||= {}
      end

      def full_scopes
        scopes.merge(self.superclass.respond_to?(:scopes) ? self.superclass.scopes : {})
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

      def all(new_var = nil)
        var = new_var || (current_scope ? current_scope.node_identity : :n)
        if current_scope
          current_scope.new_link(var)
        else
          self.as(var)
        end
      end
    end

    class ScopeEvalContext
      def initialize(target, query_proxy)
        @query_proxy = query_proxy
        @target = target
      end

      Neo4j::ActiveNode::Query::QueryProxy::METHODS.each do |method|
        module_eval(%{
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
        return if VALID_SCOPE_TYPES.include?(scope_type)

        fail ArgumentError, "Invalid scope type '#{scope_type}' sent to the registry. Scope types must be included in VALID_SCOPE_TYPES"
      end
    end
  end
end
