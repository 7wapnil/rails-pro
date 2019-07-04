# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class SkrillForm
        include ActiveModel::Model

        attr_accessor :skrill_email_address

        validates :skrill_email_address, presence: true
      end
    end
  end
end
