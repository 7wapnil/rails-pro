# frozen_string_literal: true

module EveryMatrix
  class TransactionDecorator < ApplicationDecorator
    PRECISION = 2

    delegate :play_item, to: :em_wallet_session, allow_nil: true

    delegate :code, to: :currency, allow_nil: true, prefix: true

    delegate :username, to: :customer, allow_nil: true, prefix: true

    delegate :name, to: :play_item, allow_nil: true, prefix: true

    delegate :vendor, to: :play_item,  allow_nil: true
    delegate :content_provider, to: :play_item, allow_nil: true

    delegate :name, to: :vendor, prefix: true
    delegate :name, to: :content_provider, prefix: true

    def type(human: false)
      human ? super().demodulize : super()
    end

    def amount(human: false)
      human ? human_number(super()) : super()
    end

    def amount_before(human: false)
      human ? human_number(calculate_amount_before) : calculate_amount_before
    end

    def amount_after(human: false)
      human ? human_number(fetch_amount_after) : fetch_amount_after
    end

    def base_currency_amount(human: false)
      human ? human_number(convert_to_base(amount)) : convert_to_base(amount)
    end

    def base_currency_amount_before(human: false)
      converted_amount = convert_to_base(amount_before)
      human ? human_number(converted_amount) : converted_amount
    end

    def base_currency_amount_after(human: false)
      converted_amount = convert_to_base(amount_after)
      human ? human_number(converted_amount) : converted_amount
    end

    def created_at(human: false)
      human ? l(super(), format: :long) : super()
    end

    private

    def human_number(amount)
      number_with_precision(amount, precision: PRECISION)
    end

    def convert_to_base(amount)
      Exchanger::Converter.call(
        amount,
        currency,
        Currency.primary
      )
    end

    def fetch_amount_after
      response['Balance'].to_f
    end

    def calculate_amount_before
      amount_after + amount_with_sign
    end

    def amount_with_sign
      (EveryMatrix::Transaction::DEBIT_TYPES.include?(type) ? amount : -amount)
    end
  end
end
