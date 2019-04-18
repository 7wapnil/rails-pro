module Exchanger
  module Apis
    class CoinApi < BaseApi
      base_uri 'https://rest.coinapi.io/v1'
      headers 'X-CoinAPI-Key': ENV['COIN_API_KEY']

      protected

      def request
        self.class.get("/exchangerate/#{@base}", query: {
                         filter_asset_id: currencies_list_param
                       })
      end

      def parse(formatted_response)
        formatted_response['rates'].to_a.map do |item|
          Rate.new(item['asset_id_quote'], item['rate'])
        end
      end
    end
  end
end
