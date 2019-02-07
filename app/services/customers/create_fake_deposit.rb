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
      return unless payment_provider.pay!(amount, fake_credit)

      EntryRequests::DepositService.call(entry_request: created_entry_request)

      true
    rescue StandardError => e
      Rails.logger.error("DEPOSIT ERROR: #{e.message}")
      false
    end

    private

    attr_accessor :customer, :amount, :currency_id,
                  :fake_credit, :payment_provider

    def created_entry_request
      @created_entry_request ||= EntryRequests::Factories::Deposit.call(
        wallet: wallet,
        amount: amount
      )
    end

    def wallet
      @wallet ||= Wallet.find_or_create_by!(customer: customer,
                                            currency_id: currency_id)
    end
  end
end
