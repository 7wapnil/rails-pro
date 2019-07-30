# frozen_string_literal: true

module Payments
  module Withdrawals
    module Customers
      class RulesForm
        include ActiveModel::Model

        attr_accessor :password, :customer

        validates :password, :customer, presence: true

        validate :validate_password
        validate :validate_status

        def validate_status
          return if !customer || customer.verified

          errors.add(:status,
                     I18n.t('errors.messages.withdrawal.customer_not_verified'))
        end

        def validate_password
          return if !customer || customer.valid_password?(password)

          errors.add(:password, I18n.t('errors.messages.password_invalid'))
        end
      end
    end
  end
end
