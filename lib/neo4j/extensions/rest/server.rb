module Neo4j

  module Rest
    # todo move inside namepace Rest

    class RestServer
      class << self
        attr_accessor :thread

        def on_neo_started(neo_instance)
          start
        end

        def on_neo_stopped(neo_instance)
          stop
        end


        def start
          puts "RESTful already started" if @thread
          return if @thread

          @thread = Thread.new do
            puts "Start Restful server at port #{Neo4j::Config[:rest_port]}"
            Sinatra::Application.run! :port => Neo4j::Config[:rest_port]
          end
        end

        def stop
          if @thread
            # TODO must be a nicer way to do this - to shutdown sinatra
            @thread.kill
            @thread = nil
          end
        end
      end
    end


    def self.load_rest #:nodoc:
      Neo4j::Config.defaults[:rest_port] = 9123
      Neo4j.event_handler.add(RestServer)
    end

    load_rest

  end


end
