# Copied largely from activerecord/lib/active_record/log_subscriber.rb
module Neo4j
  module Core
    module Logging
      class << self
        def first_external_path_and_line(callstack)
          line = callstack.find do |frame|
            frame.absolute_path && !ignored_callstack(frame.absolute_path)
          end

          offending_line = line || callstack.first

          [offending_line.path,
           offending_line.lineno]
        end

        NEO4J_CORE_GEM_ROOT = File.expand_path('../../..', __dir__) + '/'

        def ignored_callstack(path)
          paths_to_ignore.any?(&path.method(:start_with?))
        end

        def paths_to_ignore
          @paths_to_ignore ||= [NEO4J_CORE_GEM_ROOT,
                                RbConfig::CONFIG['rubylibdir'],
                                neo4j_gem_path,
                                active_support_gem_path].compact
        end

        def neo4j_gem_path
          return if !defined?(::Rails.root)

          @neo4j_gem_path ||= File.expand_path('../../..', Neo4j::ActiveBase.method(:current_session).source_location[0])
        end

        def active_support_gem_path
          return if !defined?(::ActiveSupport::Notifications)

          @active_support_gem_path ||= File.expand_path('../../..', ActiveSupport::Notifications.method(:subscribe).source_location[0])
        end
      end
    end
  end
end
