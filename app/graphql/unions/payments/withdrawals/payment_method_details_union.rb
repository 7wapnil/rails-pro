# frozen_string_literal: true

module Payments
  module Withdrawals
    class PaymentMethodDetailsUnion < GraphQL::Schema::Union
      graphql_name 'PaymentsWithdrawalsPaymentMethodDetails'
      description 'Dynamic payment method details'
      possible_types ::Payments::Methods::BitcoinType,
                     ::Payments::Methods::CreditCardType,
                     ::Payments::Methods::NetellerType,
                     ::Payments::Methods::SkrillType

      TYPES_MAP = {
        ::Payments::Methods::CREDIT_CARD => ::Payments::Methods::CreditCardType,
        ::Payments::Methods::SKRILL => ::Payments::Methods::SkrillType,
        ::Payments::Methods::NETELLER => ::Payments::Methods::NetellerType,
        ::Payments::Methods::BITCOIN => ::Payments::Methods::BitcoinType
      }.freeze

      def self.resolve_type(obj, _ctx)
        TYPES_MAP[obj.payment_method]
      end
    end
  end
end