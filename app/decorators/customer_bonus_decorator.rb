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
    amount = balance_entry ? balance_entry.amount : 0.0

    human ? "#{amount} #{currency}" : amount
  end

  def max_rollover_per_bet(human: false)
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
    entry ? link_to(t('entities.entry'), entry_path(entry)) : t('not_available')
  end

  def link_to_customer
    link_to(customer.full_name, customer_path(customer))
  end

  def percentage(human: false)
    human ? number_to_percentage(super(), precision: 0) : super()
  end
end
