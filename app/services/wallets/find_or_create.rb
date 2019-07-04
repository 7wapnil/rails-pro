# frozen_string_literal: true

module Wallets
  class FindOrCreate < ApplicationService
    attr_reader :params, :currency_id, :customer_id

    def initialize(params)
      @params = params
      @currency_id = params[:currency_id] || params[:currency]&.id
      @customer_id = params[:customer_id] || params[:customer]&.id
    end

    def call
      find_wallet || create_wallet!
    end

    private

    def find_wallet
      Wallet.find_by(currency_id: currency_id, customer_id: customer_id)
    end

    def create_wallet!
      form.submit!
    rescue ActiveModel::ValidationError
      raise Wallets::ValidationError, form.errors.full_messages.first
    end

    def form
      @form ||= Wallets::CreateForm.new(
        subject: Wallet.new(params)
      )
    end
  end
end
