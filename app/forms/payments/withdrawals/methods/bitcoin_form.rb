# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class BitcoinForm
        include ActiveModel::Model

        attr_accessor :bitcoin_address

        validates :bitcoin_address, presence: true
      end
    end
  end
end
