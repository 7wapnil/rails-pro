# frozen_string_literal: true

module SafeCharge
  module Withdraw
    AVAILABLE_WITHDRAW_MODES = {
      EntryRequest::CREDIT_CARD => [EntryRequest::CREDIT_CARD]
    }.freeze

    WITHDRAW_MODE_FIELDS = {
      EntryRequest::CREDIT_CARD => [
        {
          name: "Holder's full name",
          code: :full_name,
          type: :string
        },
        {
          name: "Card's last four digits",
          code: :last_four_digits,
          type: :string
        }
      ]
    }.freeze
  end
end
