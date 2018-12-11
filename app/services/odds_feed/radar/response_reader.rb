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
        validate_response

        Rails.cache.write(cache_key, response) if cache

        response
      end

      def response
        @response ||= Radar::Client.send(method, path, options).parsed_response
      end

      def validate_response
        Rails.logger.debug "Radar API response: #{response}"
        raise OddsFeed::InvalidResponseError, error['message'] if error
      end

      def error
        @error ||= response['error']
      end
    end
  end
end
