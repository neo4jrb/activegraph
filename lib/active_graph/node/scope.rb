module ActiveGraph::Node
  module Scope
    extend ActiveSupport::Concern

    included do
      thread_mattr_accessor :current_scope
    end

    module ClassMethods
      # Similar to ActiveRecord scope
      #
      # @example without argument
      #   class Person
      #     include ActiveGraph::Node
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
      #     include ActiveGraph::Node
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
          define_method(name) do |*query_params, **kwargs|
            eval_context = ScopeEvalContext.new(self, current_scope || self.query_proxy)
            proc = full_scopes[name.to_sym]
            _call_scope_context(eval_context, *query_params, **kwargs, &proc)
          end
        end

        define_method(name) do |*query_params, **kwargs|
          as(:n).public_send(name, *query_params, **kwargs)
        end
      end

      # rubocop:disable Naming/PredicateName
      def has_scope?(name)
        ActiveSupport::Deprecation.warn 'has_scope? is deprecated and may be removed from future releases, use scope? instead.', caller

        scope?(name)
      end
      # rubocop:enable Naming/PredicateName

      # @return [Boolean] true if model has access to scope with this name
      def scope?(name)
        full_scopes.key?(name.to_sym)
      end

      # @return [Hash] of scopes assigned to this model. Keys are scope name, value is scope callable.
      def scopes
        @scopes ||= {}
      end

      # @return [Hash] of scopes available to this model. Keys are scope name, value is scope callable.
      def full_scopes
        self.ancestors.find_all { |a| a.respond_to?(:scopes) }.reverse.inject({}) do |scopes, a|
          scopes.merge(a.scopes)
        end
      end

      def _call_scope_context(eval_context, *query_params, **kwargs, &proc)
        last_vararg_index = proc.arity - (kwargs.empty? ? 1 : 2)
        query_params.fill(nil, query_params.length..last_vararg_index)
        if RUBY_VERSION < '3' && kwargs.empty?
          eval_context.instance_exec(*query_params, &proc)
        else
          eval_context.instance_exec(*query_params, **kwargs, &proc)
        end
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

      def identity
        query_proxy_or_target.identity
      end

      ActiveGraph::Node::Query::QueryProxy::METHODS.each do |method|
        define_method(method) do |*args|
          @target.all.scoping do
            query_proxy_or_target.public_send(method, *args)
          end
        end
      end

      # method_missing is not delegated to super class but to aggregated class
      # rubocop:disable Style/MethodMissingSuper
      def method_missing(name, *params, **kwargs, &block)
        if RUBY_VERSION < '3' && kwargs.empty?
          query_proxy_or_target.public_send(name, *params, &block)
        else
          query_proxy_or_target.public_send(name, *params, **kwargs, &block)
        end
      end
      # rubocop:enable Style/MethodMissingSuper

      private

      def query_proxy_or_target
        @query_proxy_or_target ||= @query_proxy || @target
      end
    end
  end
end
