# frozen_string_literal: true

module Payments
  module Confiscations
    module Backoffice
      class CreateForm
        include ActiveModel::Model
        include ::Payments::Methods

        MIN_AMOUNT = 0
        MAX_AMOUNT = 10_000
        AMOUNT_FORMAT_REGEX = /\A\d{1,12}(\.\d{0,2})?\z/

        attr_accessor :amount,
                      :wallet,
                      :payment_method,
                      :payment_details,
                      :customer,
                      :initiator

        validates :amount,
                  :wallet,
                  :payment_method,
                  :customer,
                  :initiator, presence: true
        validates :amount,
                  numericality: { greater_than: MIN_AMOUNT },
                  format: { with: AMOUNT_FORMAT_REGEX }

        validate :validate_currency_rule
        validate :validate_type_of_initiator

        delegate :real_money_balance, to: :wallet, allow_nil: true

        def validate_type_of_initiator
          return true if initiator.is_a? User

          errors.add(:initiator, I18n.t('errors.messages.initiator_type'))
        end

        def validate_currency_rule
          return true unless rule
          return amount_greater_than_allowed! if amount > rule.min_amount.abs

          amount_less_than_allowed! if -amount > rule.max_amount
        end

        def rule
          @rule ||= EntryCurrencyRule.find_by(currency: currency,
                                              kind: EntryKinds::CONFISCATION)
        end

        def currency
          @currency ||= wallet&.currency
        end

        def amount_less_than_allowed!
          errors.add(:amount,
                     I18n.t('errors.messages.min_confiscation_amount_reached',
                            min_amount: rule.max_amount.abs,
                            currency: currency.to_s))
        end

        def amount_greater_than_allowed!
          errors.add(:amount,
                     I18n.t('errors.messages.max_confiscation_amount_reached',
                            max_amount: rule.min_amount.abs,
                            currency: currency.to_s))
        end
      end
    end
  end
end
