require 'active_support/notifications'

module Neo4j
  module Core
    module Instrumentable
      def self.included(base)
        base.send :include, InstanceMethods
        base.extend ClassMethods
      end

      module InstanceMethods
      end

      module ClassMethods
        def instrument(name, label, arguments)
          # defining class methods
          klass = class << self; self; end
          klass.instance_eval do
            define_method("subscribe_to_#{name}") do |&b|
              ActiveSupport::Notifications.subscribe(label) do |a, start, finish, id, payload|
                b.call yield(a, start, finish, id, payload)
              end
            end

            define_method("instrument_#{name}") do |*args, &b|
              hash = arguments.each_with_index.each_with_object({}) do |(argument, i), result|
                result[argument.to_sym] = args[i]
              end
              ActiveSupport::Notifications.instrument(label, hash) { b.call }
            end
          end
        end
      end
    end
  end
end
