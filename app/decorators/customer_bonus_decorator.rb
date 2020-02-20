# frozen_string_literal: true

class CustomerBonusDecorator < ApplicationDecorator
  EXPIRES_AT_FORMAT = '%e.%m.%y'

  def expires_at(human: false)
    human ? super().strftime(EXPIRES_AT_FORMAT) : super()
  end

  def active_until_date(human: false)
    human ? super().strftime(EXPIRES_AT_FORMAT) : super()
  end

  def amount(human: false)
    amount = activation_entry ? activation_entry.bonus_amount : 0.0

    human ? "#{amount} #{currency}" : amount
  end

  def lost_amount(human: false)
    amount = lost? ? activation_entry&.bonus_amount.to_f : 0.0

    human ? "#{amount} #{currency}" : amount
  end

  def cancelled_amount(human: false)
    amount = cancelled? ? cancellation_entry&.bonus_amount.to_f : 0.0

    human ? "#{switch_sign(amount)} #{currency}" : switch_sign(amount)
  end

  def expired_amount(human: false)
    amount = expired? ? expiration_entry&.bonus_amount.to_f : 0.0

    human ? "#{switch_sign(amount)} #{currency}" : switch_sign(amount)
  end

  def total_converted_amount(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def total_confiscated_amount(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def max_rollover_per_bet(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def max_rollover_per_spin(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def max_deposit_match(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def min_deposit(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def rollover_balance(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def rollover_initial_value(human: false)
    human ? "#{super()} #{currency}" : super()
  end

  def link_to_entry
    return t('internal.not_available') unless activation_entry.present?

    link_to(t('internal.entities.entry'), entry_path(activation_entry))
  end

  def link_to_customer
    link_to(customer.full_name, customer_path(customer))
  end

  def percentage(human: false)
    human ? number_to_percentage(super(), precision: 0) : super()
  end

  private

  def switch_sign(number)
    return number if number.zero?

    -number
  end
end
