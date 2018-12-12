module OddsFeed
  module Radar
    class ResponseReader < ApplicationService
      CLIENT_KEY = 'radar-client'.freeze

      def initialize(path:, method:, **params)
        @path    = path
        @method  = method
        @cache   = params[:cache]
        @options = params.fetch(:options, {})
      end

      def call
        return api_call unless cached_data?

        Rails.logger.info "Cached data loaded for `#{path}`"
        Rails.logger.debug "Loaded data: #{cached_response}"
        cached_response
      end

      private

      attr_reader :path, :method, :cache, :options

      def cached_data?
        cache && cached_response
      end

      def cached_response
        @cached_response ||= Rails.cache.read(cache_key)
      end

      def cache_key
        @cache_key ||= "#{CLIENT_KEY}:#{path}"
      end

      def api_call
        Rails.logger.debug "Requesting Radar API endpoint: #{path}"
        Rails.logger.debug "Radar API response: #{response.body}"

        Rails.cache.write(cache_key, parsed_response, cache_settings) if cache

        parsed_response
      rescue RuntimeError, MultiXml::ParseError => e
        Rails.logger.error [e.message, response.body]
        raise HTTParty::ResponseError, 'Malformed response body'
      end

      def response
        @response ||= Radar::Client.send(method, path, options)
      end

      def parsed_response
        @parsed_response ||= response.parsed_response || {}
      end

      def cache_settings
        cache.is_a?(Hash) ? cache : {}
      end
    end
  end
end
