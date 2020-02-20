# frozen_string_literal: true

module CustomerBonuses
  class CreateForm
    include ActiveModel::Model

    NON_COUNTABLE_DEPOSITS = [
      EntryRequest::CASHIER,
      EntryRequest::SIMULATED
    ].freeze

    attr_reader :subject, :amount, :currency

    validate :ensure_no_active_bonus
    validate :validate_repeated_activation
    validate :minimal_bonus_amount
    validate :validate_previous_deposits_number

    delegate :customer, :original_bonus, to: :subject

    def initialize(amount:, currency: nil, **bonus_attributes)
      @amount = amount
      @currency = currency || Currency.primary
      @subject = CustomerBonus.new(bonus_attributes)
    end

    def submit!
      validate!
      lose_wager_pending_bouns! if wager_pending_bonus
      subject.save!
    end

    def validate!
      return if valid?

      raise CustomerBonuses::ActivationError, displayed_error
    end

    private

    def minimal_bonus_amount
      return if amount.present? && amount >= min_deposit

      errors.add(:bonus,
                 I18n.t('errors.messages.bonus_minimum_requirements_failed'))
    end

    def ensure_no_active_bonus
      return unless active_bonus
      return if wager_pending_bonus

      errors.add(:active_bonus,
                 I18n.t('errors.messages.customer_has_active_bonus'))
    end

    def active_bonus
      @active_bonus ||= customer&.active_bonus
    end

    def wager_pending_bonus
      return unless active_bonus

      has_pending_wagers =
        EveryMatrix::Wager
        .where(customer_bonus: active_bonus)
        .pending_bonus_loss
        .any?

      return active_bonus if has_pending_wagers
    end

    def lose_wager_pending_bouns!
      Deactivate.call(
        bonus: wager_pending_bonus,
        action: Deactivate::LOSE
      )
    end

    def validate_repeated_activation
      return if original_bonus.repeatable

      duplicate = CustomerBonus.find_by(customer: customer,
                                        original_bonus: original_bonus,
                                        status: CustomerBonus::USED_STATUSES)
      return unless duplicate

      errors.add(:bonus,
                 I18n.t('errors.messages.repeated_bonus_activation'))
    end

    def validate_previous_deposits_number
      return unless original_bonus.previous_deposits_number
      return if previous_deposits_number_matches?

      errors.add(:bonus,
                 I18n.t('errors.messages.previous_deposits_number_violation',
                        number: original_bonus.previous_deposits_number))
    end

    def previous_deposits_number_matches?
      successful_deposits_count == original_bonus.previous_deposits_number
    end

    def successful_deposits_count
      Entry
        .where(kind: Entry::DEPOSIT, wallet: customer.wallets)
        .joins(:entry_request)
        .where.not(entry_requests: { mode: NON_COUNTABLE_DEPOSITS })
        .count
    end

    def displayed_error
      # [1] takes the error message itself instead of key-value pair
      errors.first[1]
    end

    def min_deposit
      @min_deposit ||= Exchanger::Converter.call(
        original_bonus.min_deposit,
        Currency.primary,
        currency
      )
    end
  end
end
