# frozen_string_literal: true

class BetDecorator < ApplicationDecorator
  PRECISION = 2

  delegate :code, to: :currency, allow_nil: true, prefix: true

  delegate :name, to: :odd, allow_nil: true, prefix: true

  delegate :name, to: :market, allow_nil: true, prefix: true

  delegate :name, to: :event, allow_nil: true, prefix: true

  delegate :username, to: :customer, allow_nil: true, prefix: true

  def amount(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def winning_amount(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def base_currency_amount(human: false)
    human ? number_with_precision(super(), precision: PRECISION) : super()
  end

  def created_at(human: false)
    human ? l(created_at, format: :long) : super()
  end
end
