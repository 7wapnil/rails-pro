# frozen_string_literal: true

module Exchanger
  module Apis
    class BaseApi < ApplicationService
      include HTTParty

      raise_on [400, 401, 403, 429, 500, 550]

      def initialize(base, currencies, default: [])
        @base = base
        @currencies = Array(default) | currencies.reject { |code| code == base }
      end

      def call
        log(:info, 'Requesting new currencies rates')
        response = request.parsed_response
        return [] unless response

        parse(response)
      rescue HTTParty::ResponseError => e
        log(:error, e.message)

        []
      end

      protected

      attr_reader :base, :currencies

      def request
        raise NotImplementedError, 'Must be implemented by child classes'
      end

      def parse(_formatted_response)
        raise NotImplementedError, 'Must be implemented by child classes'
      end

      private

      def log(level, message)
        Rails.logger.send(
          level,
          message:              message,
          api:                  self.class.name,
          base_currency:        base,
          currencies_to_update: currencies
        )
      end
    end
  end
end
