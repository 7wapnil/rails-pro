module DepositLimitsValidation
  class Service < ApplicationService
    def initialize(entry_request)
      @entry_request = entry_request
    end

    def call
      @customer = @entry_request.customer
      @deposit_limit = @customer.deposit_limit
      return unless @deposit_limit

      @limit_currency = @deposit_limit.currency
      @money_converter = MoneyConverter::Service.new
      apply_deposit_limit!
    end

    private

    def apply_deposit_limit!
      sum = initial_value
      entries.each do |entry|
        sum += @money_converter.convert(
          entry.amount,
          entry.wallet.currency.code,
          @limit_currency.code
        )
        return validation_failed! if sum >= @deposit_limit.value
      end
    end

    def initial_value
      @money_converter.convert(
        @entry_request.amount,
        @entry_request.currency.code,
        @limit_currency.code
      )
    end

    def entries
      Entry
        .joins(:wallet)
        .includes(wallet: :currency)
        .where(
          wallets: { customer: @customer },
          kind: :deposit
        )
        .where(
          'entries.created_at > ?',
          Time.zone.now - @deposit_limit.range.days
        )
    end

    def validation_failed!
      @customer.log_event :deposit_limit_validation_failed
      @entry_request.errors.add(
        :kind,
        ::I18n.t('errors.messages.deposit_limits')
      )
    end
  end
end
