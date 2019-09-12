# frozen_string_literal: true

module Exchanger
  module Apis
    class BaseApi < ApplicationService
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

      protected

      attr_reader :base_currency_code, :currency_codes

      def response
        @response ||= request.parsed_response
      end

      def request
        raise NotImplementedError, 'Must be implemented by child classes'
      end

      def parse(_formatted_response)
        raise NotImplementedError, 'Must be implemented by child classes'
      end

      private

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
