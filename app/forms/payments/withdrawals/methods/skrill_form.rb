# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class SkrillForm
        include ActiveModel::Model

        attr_accessor :email

        validates :email, presence: true
      end
    end
  end
end
