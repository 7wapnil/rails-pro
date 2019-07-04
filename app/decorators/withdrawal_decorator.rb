# frozen_string_literal: true

class WithdrawalDecorator < ApplicationDecorator
  delegate :customer, to: :entry_request, allow_nil: true
  delegate :mode,     to: :entry_request, allow_nil: true
  delegate :amount,   to: :entry_request, allow_nil: true
  delegate :currency, to: :entry_request, allow_nil: true
end
