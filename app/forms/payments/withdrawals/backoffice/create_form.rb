# frozen_string_literal: true

module Payments
  module Withdrawals
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
                      :customer

        validates :amount,
                  :wallet,
                  :payment_method,
                  :customer, presence: true
        validates :amount,
                  numericality: { greater_than: MIN_AMOUNT },
                  format: { with: AMOUNT_FORMAT_REGEX }

        validate :validate_no_pending_bets_with_bonus
        validate :validate_amount
        validate :validate_currency_rule

        delegate :real_money_balance, to: :wallet, allow_nil: true

        def validate_no_pending_bets_with_bonus
          return if !customer || no_pending_bets_with_bonus?

          errors.add(
            :base,
            I18n.t('errors.messages.backoffice.pending_bets_with_bonus')
          )
        end

        def no_pending_bets_with_bonus?
          customer
            .bets
            .pending
            .joins(:entry_requests)
            .none?
        end

        def validate_amount
          return unless amount && real_money_balance
          return if amount <= real_money_balance

          errors.add(
            :base,
            I18n.t('errors.messages.backoffice.not_enough_money')
          )
        end

        def validate_currency_rule
          return true unless rule
          return amount_greater_than_allowed! if amount > rule.min_amount.abs

          amount_less_than_allowed! if -amount > rule.max_amount
        end

        def rule
          @rule ||= EntryCurrencyRule.find_by(currency: currency,
                                              kind: EntryKinds::WITHDRAW)
        end

        def currency
          @currency ||= wallet&.currency
        end

        def amount_less_than_allowed!
          errors.add(:amount,
                     I18n.t('errors.messages.minimum_withdrawal_amount_reached',
                            min_amount: rule.max_amount.abs,
                            currency: currency.to_s))
        end

        def amount_greater_than_allowed!
          errors.add(:amount,
                     I18n.t('errors.messages.maximum_withdrawal_amount_reached',
                            max_amount: rule.min_amount.abs,
                            currency: currency.to_s))
        end
      end
    end
  end
end
