# frozen_string_literal: true

module Exchanger
  module Apis
    class ExchangeRatesApi < ApplicationService
      include HTTParty

      raise_on [400, 401, 403, 429, 500, 550]

      def initialize(base_currency_code, currency_codes)
        @base_currency_code = base_currency_code
        @currency_codes = currency_codes
      end

      def call
        Rails.logger.info(log_params('Requesting new currencies rates'))

        return [] unless response

        parse(response)
      rescue HTTParty::ResponseError => e
        Rails.logger.error(log_params(e.message).merge(error_object: e))

        []
      end

      private

      attr_reader :base_currency_code, :currency_codes

      def response
        @response ||= request.parsed_response
      end

      def request
        self.class.get(
          "#{ENV['FIXER_API_URL']}/api/latest",
          query: {
            base: base_currency_code,
            symbols: currency_codes.join(','),
            access_key: ENV['FIXER_API_KEY']
          }
        )
      end

      def parse(formatted_response)
        formatted_response['rates']
          .to_a
          .map { |code, value| Rate.new(code, value) }
      end

      def log_params(message)
        {
          message:              message,
          api:                  self.class.name,
          base_currency:        base_currency_code,
          currencies_to_update: currency_codes
        }
      end
    end
  end
end
