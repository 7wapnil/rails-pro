module OddsFeed
  module Radar
    class ResponseReader < ApplicationService
      include JobLogger

      CLIENT_KEY = 'radar-client'.freeze

      def initialize(path:, method:, **params)
        @path    = path
        @method  = method
        @cache   = params[:cache]
        @options = params.fetch(:options, {})
      end

      def call
        return api_call unless cached_data?

        log_job_message(:info, message: 'Cached data loaded', path: path)
        log_job_message(:debug, message: 'Loaded data',
                                response: cached_response)
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
        log_job_message(:debug, message: 'Requesting Radar API endpoint',
                                path: path)
        log_job_message(:debug, message: 'Radar API response',
                                response: response.body)

        Rails.cache.write(cache_key, parsed_response, cache_settings) if cache

        parsed_response
      rescue RuntimeError, MultiXml::ParseError => error
        log_job_failure(error)
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
