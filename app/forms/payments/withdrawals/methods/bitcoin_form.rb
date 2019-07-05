# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class BitcoinForm
        include ActiveModel::Model

        BITCOIN_ADDRESS_FORMAT_REGEX = /\A(1|3)[a-zA-Z1-9]{26,34}\z/

        attr_accessor :bitcoin_address

        validates :bitcoin_address, presence: true
        validates :bitcoin_address,
                  format: { with: BITCOIN_ADDRESS_FORMAT_REGEX }
      end
    end
  end
end
