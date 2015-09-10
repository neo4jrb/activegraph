Railtie
=======






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/railtie.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/railtie.rb#L5>`_





Methods
-------



.. _`Neo4j/Railtie.java_platform?`:

**.java_platform?**
  

  .. code-block:: ruby

     def java_platform?
       RUBY_PLATFORM =~ /java/
     end



.. _`Neo4j/Railtie.open_neo4j_session`:

**.open_neo4j_session**
  

  .. code-block:: ruby

     def open_neo4j_session(options)
       type, name, default, path = options.values_at(:type, :name, :default, :path)
     
       if !java_platform? && type == :embedded_db
         fail "Tried to start embedded Neo4j db without using JRuby (got #{RUBY_PLATFORM}), please run `rvm jruby`"
       end
     
       session = if options.key?(:name)
                   Neo4j::Session.open_named(type, name, default, path)
                 else
                   Neo4j::Session.open(type, path, options[:options])
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
         (Neo4j::Config[:logger] || Rails.logger).info message
       end
     
       @neo4j_cypher_logging_registered = true
     end



.. _`Neo4j/Railtie.setup_config_defaults!`:

**.setup_config_defaults!**
  

  .. code-block:: ruby

     def setup_config_defaults!(cfg)
       cfg.session_type ||= :server_db
       cfg.session_path ||= 'http://localhost:7474'
       cfg.session_options ||= {}
       cfg.sessions ||= []
     
       uri = URI(cfg.session_path)
       return if uri.user.blank?
     
       cfg.session_options.reverse_merge!(basic_auth: {username: uri.user, password: uri.password})
       cfg.session_path = cfg.session_path.gsub("#{uri.user}:#{uri.password}@", '')
     end



.. _`Neo4j/Railtie.setup_default_session`:

**.setup_default_session**
  

  .. code-block:: ruby

     def setup_default_session(cfg)
       setup_config_defaults!(cfg)
     
       return if !cfg.sessions.empty?
     
       cfg.sessions << {type: cfg.session_type, path: cfg.session_path, options: cfg.session_options}
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





