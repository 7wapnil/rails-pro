module Exchanger
  module Apis
    class ExchangeRatesApiIo < BaseApi
      base_uri 'https://api.exchangeratesapi.io'

      protected

      def request
        self.class.get('/latest', query: { base: @base,
                                           symbols: @currencies.join(',') })
      end

      def parse(formatted_response)
        formatted_response['rates'].to_a.map do |code, value|
          Rate.new(code, value)
        end
      end
    end
  end
end
