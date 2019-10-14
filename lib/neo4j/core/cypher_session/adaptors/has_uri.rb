require 'active_support/concern'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        # Containing the logic for dealing with adaptors which use URIs
        module HasUri
          extend ActiveSupport::Concern

          module ClassMethods
            attr_reader :default_uri

            def default_url(default_url)
              @default_uri = uri_from_url!(default_url)
            end

            def validate_uri(&block)
              @uri_validator = block
            end

            def uri_from_url!(url)
              validate_url!(url)

              @uri = url.nil? ? @default_uri : URI(url)

              fail ArgumentError, "Invalid URL: #{url.inspect}" if uri_valid?(@uri)

              @uri
            end

            private

            def validate_url!(url)
              fail ArgumentError, "Invalid URL: #{url.inspect}" if !(url.is_a?(String) || url.nil?)
              fail ArgumentError, 'No URL or default URL specified' if url.nil? && @default_uri.nil?
            end

            def uri_valid?(uri)
              @uri_validator && !@uri_validator.call(uri)
            end
          end

          def url
            @uri.to_s
          end

          def url=(url)
            @uri = self.class.uri_from_url!(url)
          end

          def url_without_password
            @url_without_password ||= "#{scheme}://#{user + ':...@' if user}#{host}:#{port}"
          end

          included do
            %w[scheme user password host port].each do |method|
              define_method(method) do
                (@uri && @uri.send(method)) || (self.class.default_uri && self.class.default_uri.send(method))
              end
            end
          end
        end
      end
    end
  end
end
