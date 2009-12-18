module Neo4j
  module Rest
    module RestStubMixin
      attr_accessor :json

      def initialize(uri_or_json_hash)
        if uri_or_json_hash.kind_of?(Hash)
          @json = uri_or_json_hash
        else
          @json = RestHttpMethods.get_request(uri_or_json_hash)
        end
      end

      def [](key)
        @json['properties'][key.to_s]
      end

      def relationships
        RelationshipTraverserStub.new(@json['rels'])
      end


      def relationship?(type, dir=:outgoing)
        rels.rel?(type, dir)
      end

      def props
        @json['properties']
      end
    end

    module RestHttpMethods
      class << self
        def get_request(resource, args = {})
          body = _get_request(resource, args)
          JSON.parse(body)
        end

        def _get_request(resource, args)
          _request(resource, :get, args)
        end

        def _request(resource, method = :get, args = {})
          url = URI.parse(resource)
          host = url.host
          host.sub!(/0\.0\.0\.0/, 'localhost')

          #if args
          #  url.query = args.map { |k, v| "%s=%s" % [URI.encode(k), URI.encode(v)] }.join("&")
          #end

          req =
                  case method
                    when :put
                      Net::HTTP::Put.new(url.path)
                    when :get
                      Net::HTTP::Get.new(url.path)
                    when :post
                      Net::HTTP::Post.new(url.path)
                  end

          http = Net::HTTP.new(host, url.port)
          res = http.start() { |conn| conn.request(req) }
          res.body
        end
      end
    end


    class RelationshipStub
      include RestStubMixin

      def start_node
        uri = @json['start_node']['uri']
        NodeStub.new(uri)
      end

      def end_node
        uri = @json['end_node']['uri']
        NodeStub.new(uri)
      end

    end

    class RelationshipTraverserStub
      include Enumerable

      def initialize(json)
        @json = json
      end

      def outgoing(rel_type)
        @rel_type = rel_type
        self
      end

      def relationship?(type, dir=:outgoing)
        !@json[type.to_s].nil?
      end

      def nodes
        @return_nodes = true
        self
      end

      def first
        each do |x|
          return x if !block_given? || yield(x)
        end
      end

      def each
        keys =
                if @rel_type.nil?
                  @json.keys # take all keys
                else
                  [@rel_type.to_s]
                end

        keys.each do |rel_type|
          next unless rel?(rel_type)
          if @return_nodes
            @json[rel_type.to_s].each {|uri| yield RelationshipStub.new(uri).end_node}
          else
            @json[rel_type.to_s].each {|uri| yield RelationshipStub.new(uri)}
          end
        end
      end
    end

    class NodeStub
      include RestStubMixin
    end

  end
end