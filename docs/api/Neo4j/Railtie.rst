Railtie
=======






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/railtie.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/railtie.rb#L7>`_





Methods
-------



.. _`Neo4j/Railtie.config_data`:

**.config_data**
  

  .. code-block:: ruby

     def config_data
       @config_data ||= if yaml_path
                          HashWithIndifferentAccess.new(YAML.load(ERB.new(yaml_path.read).result)[Rails.env])
                        else
                          {}
                        end
     end



.. _`Neo4j/Railtie.default_session_path`:

**.default_session_path**
  

  .. code-block:: ruby

     def default_session_path
       ENV['NEO4J_URL'] || ENV['NEO4J_PATH'] ||
         config_data[:url] || config_data[:path] ||
         'http://localhost:7474'
     end



.. _`Neo4j/Railtie.default_session_type`:

**.default_session_type**
  

  .. code-block:: ruby

     def default_session_type
       if ENV['NEO4J_TYPE']
         :embedded_db
       else
         config_data[:type] || :server_db
       end.to_sym
     end



.. _`Neo4j/Railtie.java_platform?`:

**.java_platform?**
  

  .. code-block:: ruby

     def java_platform?
       RUBY_PLATFORM =~ /java/
     end



.. _`Neo4j/Railtie.open_neo4j_session`:

**.open_neo4j_session**
  

  .. code-block:: ruby

     def open_neo4j_session(options, wait_for_connection = false)
       type, name, default, path = options.values_at(:type, :name, :default, :path)
     
       if !java_platform? && type == :embedded_db
         fail "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
       end
     
       session = wait_for_value(wait_for_connection) do
         if options.key?(:name)
           Neo4j::Session.open_named(type, name, default, path)
         else
           Neo4j::Session.open(type, path, options[:options])
         end
       end
     
       start_embedded_session(session) if type == :embedded_db
     end



.. _`Neo4j/Railtie#register_neo4j_cypher_logging`:

**#register_neo4j_cypher_logging**
  

  .. code-block:: ruby

     def register_neo4j_cypher_logging
       return if @neo4j_cypher_logging_registered
     
       Neo4j::Core::Query.pretty_cypher = Neo4j::Config[:pretty_logged_cypher_queries]
     
       Neo4j::Server::CypherSession.log_with do |message|
         (Neo4j::Config[:logger] || Rails.logger).debug message
       end
     
       @neo4j_cypher_logging_registered = true
     end



.. _`Neo4j/Railtie.setup_config_defaults!`:

**.setup_config_defaults!**
  

  .. code-block:: ruby

     def setup_config_defaults!(cfg)
       cfg.session_type ||= default_session_type
       cfg.session_path ||= default_session_path
       cfg.session_options ||= {}
       cfg.sessions ||= []
     end



.. _`Neo4j/Railtie.setup_default_session`:

**.setup_default_session**
  

  .. code-block:: ruby

     def setup_default_session(cfg)
       setup_config_defaults!(cfg)
     
       return if !cfg.sessions.empty?
     
       cfg.sessions << {type: cfg.session_type, path: cfg.session_path, options: cfg.session_options.merge(default: true)}
     end



.. _`Neo4j/Railtie.start_embedded_session`:

**.start_embedded_session**
  

  .. code-block:: ruby

     def start_embedded_session(session)
       # See https://github.com/jruby/jruby/wiki/UnlimitedStrengthCrypto
       security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
       restricted_field = security_class.get_declared_field('isRestricted')
       restricted_field.accessible = true
       restricted_field.set nil, false
       session.start
     end



.. _`Neo4j/Railtie#wait_for_value`:

**#wait_for_value**
  

  .. code-block:: ruby

     def wait_for_value(wait)
       session = nil
       Timeout.timeout(60) do
         until session
           begin
             if session = yield
               puts
               return session
             end
           rescue Faraday::ConnectionFailed => e
             raise e if !wait
     
             putc '.'
             sleep(1)
           end
         end
       end
     end



.. _`Neo4j/Railtie.yaml_path`:

**.yaml_path**
  

  .. code-block:: ruby

     def yaml_path
       @yaml_path ||= %w(config/neo4j.yml config/neo4j.yaml).map do |path|
         Rails.root.join(path)
       end.detect(&:exist?)
     end





