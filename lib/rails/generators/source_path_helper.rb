module ActiveGraph::Generators::SourcePathHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def source_root
      @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                         'active_graph', generator_name, 'templates'))
    end
  end
end
