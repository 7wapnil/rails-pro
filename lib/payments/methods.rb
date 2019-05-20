module Payments
  module Methods
    CREDIT_CARD = :credit_card
    NETELLER = :neteller

    TRANSACTIONS = {
      CREDIT_CARD => Transactions::CreditCard,
      NETELLER => Transactions::Neteller
    }.freeze
  end
end
