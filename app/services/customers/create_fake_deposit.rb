module Customers
  class CreateFakeDeposit < ApplicationService
    def initialize(customer:, params: {})
      @customer = customer
      @amount = params[:amount].to_f
      @currency_id = params[:currency_id]
      @fake_credit = {}
      @payment_provider = PaymentProvider::FakeDeposit.new
    end

    def call
      create_entry_request!

      return if entry_request.failed?
      return failed_payment! unless payment_provider.pay!(amount, fake_credit)

      EntryRequests::DepositService.call(entry_request: entry_request)

      true
    rescue StandardError
      false
    end

    private

    attr_accessor :customer, :amount, :currency_id,
                  :fake_credit, :payment_provider,
                  :entry_request

    def create_entry_request!
      @entry_request = EntryRequests::Factories::Deposit.call(
        wallet: wallet,
        amount: amount
      )
    end

    def wallet
      @wallet ||= Wallet.find_or_create_by!(customer: customer,
                                            currency_id: currency_id)
    end

    def failed_payment!
      entry_request
        .register_failure!(I18n.t('errors.messages.deposit_payment_error'))
    end
  end
end
