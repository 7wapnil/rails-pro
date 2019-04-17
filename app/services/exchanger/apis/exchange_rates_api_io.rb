module Exchanger
  module Apis
    class ExchangeRatesApiIo < BaseApi
      base_uri 'https://api.exchangeratesapi.io'

      protected

      def request
        self.class.get('/latest', query: { base: @base,
                                           symbols: currencies_list_param })
      end

      def parse(formatted_response)
        formatted_response['rates'].map do |code, value|
          Rate.new(code, value)
        end
      end
    end
  end
end
