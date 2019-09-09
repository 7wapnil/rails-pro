# frozen_string_literal: true

module Exchanger
  module Apis
    class CoinApi < BaseApi
      include ::Currencies::Crypto

      base_uri 'https://rest.coinapi.io/v1'
      headers 'X-CoinAPI-Key': ENV['COIN_API_KEY']

      protected

      def request
        self.class.get("/exchangerate/#{base}",
                       query: { filter_asset_id: currencies.join(',') })
      end

      def parse(formatted_response)
        formatted_response['rates']
          .to_a
          .map { |item| Rate.new(item['asset_id_quote'], item['rate']) }
          .tap { |rates| replace_btc_with_m_btc(rates) }
      end

      private

      def replace_btc_with_m_btc(rates)
        btc_rate = rates.find { |rate| rate.code == BTC }

        return unless btc_rate

        m_btc_rate = Rate.new(m_btc_code, multiply_amount(btc_rate.value))

        rates[rates.index(btc_rate)] = m_btc_rate
      end

      def m_btc_code
        Rails.env.production? ? M_BTC : M_TBTC
      end
    end
  end
end
