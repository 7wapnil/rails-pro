module Exchanger
  module Apis
    class CoinApi < BaseApi
      BTC = 'BTC'.freeze
      MBTC = 'MBTC'.freeze

      base_uri 'https://rest.coinapi.io/v1'
      headers 'X-CoinAPI-Key': ENV['COIN_API_KEY']

      protected

      def request
        self.class.get("/exchangerate/#{@base}", query: {
                         filter_asset_id: currencies.join(',')
                       })
      end

      def parse(formatted_response)
        rates = build_rates(formatted_response['rates'].to_a)
        mbtc = build_mbtc(rates)
        rates << mbtc if mbtc.present?

        rates
      end

      private

      def build_mbtc(rates)
        btc = rates.detect { |rate| rate.code == BTC }
        return unless btc.present?

        Rate.new(MBTC, btc.value * 1000)
      end

      def build_rates(rate_data)
        rate_data.map do |item|
          Rate.new(item['asset_id_quote'], item['rate'])
        end
      end

      def currencies
        return @currencies unless mbtc_requested?
        return @currencies if @currencies.include?(BTC)

        @currencies << BTC
        @currencies
      end

      def mbtc_requested?
        @currencies.any? { |item| item == MBTC }
      end
    end
  end
end
