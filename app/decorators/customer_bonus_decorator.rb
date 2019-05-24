# frozen_string_literal: true

class CustomerBonusDecorator < ApplicationDecorator
  EXPIRES_AT_FORMAT = '%e.%m.%y'

  def expires_at(human: false)
    human ? super().strftime(EXPIRES_AT_FORMAT) : super()
  end

  def amount(human: false)
    amount = balance_entry ? balance_entry.amount : 0.0

    human ? "#{amount} #{currency}" : amount
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
