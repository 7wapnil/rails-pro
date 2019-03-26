# frozen_string_literal: true

module SafeCharge
  module Withdraw
    ONE_WAY_WITHDRAW_METHODS = [
      EntryRequest::SKRILL, EntryRequest::NETELLER
    ].freeze

    AVAILABLE_WITHDRAW_MODES = {
      EntryRequest::CREDIT_CARD => [EntryRequest::CREDIT_CARD],
      EntryRequest::SKRILL => [EntryRequest::SKRILL],
      EntryRequest::NETELLER => [EntryRequest::NETELLER],
      EntryRequest::PAYSAFECARD => ONE_WAY_WITHDRAW_METHODS,
      EntryRequest::SOFORT => ONE_WAY_WITHDRAW_METHODS,
      EntryRequest::IDEAL => ONE_WAY_WITHDRAW_METHODS,
      EntryRequest::BITCOIN =>  [EntryRequest::BITCOIN],
      EntryRequest::WEBMONEY =>  [EntryRequest::WEBMONEY],
      EntryRequest::YANDEX =>  [EntryRequest::YANDEX],
      EntryRequest::QIWI =>  [EntryRequest::QIWI]
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
      ],
      EntryRequest::NETELLER => [
        {
          name: 'Neteller account id',
          code: :neteller_account_id,
          type: :string
        },
        {
          name: 'Secure ID',
          code: :secure_id,
          type: :string
        }
      ],
      EntryRequest::SKRILL => [
        {
          name: 'Skrill email address',
          code: :skrill_email_address,
          type: :string
        }
      ],
      EntryRequest::BITCOIN => [
        {
          name: 'Bitcoin address',
          code: :bitcoin_address,
          type: :string
        }
      ]
    }.freeze
  end
end
