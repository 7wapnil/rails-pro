# frozen_string_literal: true

module Exchanger
  module Apis
    class ExchangeRatesApiIo < BaseApi
      protected

      def request
        self.class.get(
          "#{ENV['FIXER_API_URL']}/api/latest",
          query: {
            base: base,
            symbols: currencies.join(','),
            access_key: ENV['FIXER_API_KEY']
          }
        )
      end

      def parse(formatted_response)
        formatted_response['rates']
          .to_a
          .map { |code, value| Rate.new(code, value) }
      end
    end
  end
end
