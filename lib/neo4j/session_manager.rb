module Neo4j
  class SessionManager
    class << self
      def open_neo4j_session(url_or_path, options = {})
        verbose_query_logs = Neo4j::Config.fetch(:verbose_query_logs, false)
        adaptor = Neo4j::Core::CypherSession::Adaptors::Driver
                    .new(url_or_path, options.merge(wrap_level: :proc, verbose_query_logs: verbose_query_logs))
        Neo4j::Core::CypherSession.new(adaptor)
      end
    end
  end
end
