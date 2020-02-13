# frozen_string_literal: true

class CurrencyDecorator < ApplicationDecorator
  def exchange_rate(human: false)
    human ? "#{super()} #{code}" : super()
  end

  def reverse_exchange_rate(human: false)
    return unless exchange_rate

    value = (1 / exchange_rate).truncate(object.scale)

    human ? "#{value} #{Currency::PRIMARY_CODE}" : value
  end
end
