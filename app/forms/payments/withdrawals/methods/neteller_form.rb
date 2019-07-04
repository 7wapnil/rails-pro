# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class NetellerForm
        include ActiveModel::Model

        attr_accessor :neteller_account_id, :secure_id

        validates :neteller_account_id, :secure_id, presence: true
      end
    end
  end
end
