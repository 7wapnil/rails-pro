module EveryMatrix
  module Requests
    module CurrencyDenomination
      CURRENCY_DENOMINATION = {
        'mBTC' => { code: 'BTC', multiplier: 0.001 }
      }.freeze

      def denominate_currency_code(code:)
        CURRENCY_DENOMINATION.dig(code, :code) || code
      end

      def denominate_response_amount(code:, amount:)
        multiplier = CURRENCY_DENOMINATION.dig(code, :multiplier)

        return (amount * multiplier) if multiplier

        amount
      end

      def denominate_request_amount(code:, amount:)
        multiplier = CURRENCY_DENOMINATION.dig(code, :multiplier)

        return (amount / multiplier) if multiplier

        amount
      end
    end
  end
end
