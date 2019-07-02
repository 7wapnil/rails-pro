# frozen_string_literal: true

module Withdrawals
  class CreateService < ApplicationService
    def initialize(wallet:, payload:, payment_method:, amount:)
      @wallet = wallet
      @payload = payload
      @payment_method = payment_method
      @amount = amount
    end

    def call
      validate_payload

      create_entry_request!
      fail_entry_request! if entry_request.failed?
      create_withdrawal!
    end

    private

    attr_reader :wallet, :payload, :payment_method, :amount, :entry_request

    def create_entry_request!
      @entry_request = EntryRequests::Factories::Withdrawal
                       .call(wallet: wallet,
                             amount: amount,
                             mode: payment_method)
    end

    def fail_entry_request!
      raise Withdrawals::WithdrawalError, entry_request.result['message']
    end

    def validate_payload
      invalid_payment_method unless valid_withdraw_payment_method?

      required_fields.each(&method(:validate_field))
    end

    def required_fields
      SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[payment_method]
        .map { |detail| detail[:code] }
    end

    def validate_field(field)
      return if payload_hash[field.to_s].present?

      invalid_payload(field.to_s)
    end

    def valid_withdraw_payment_method?
      SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.values
                                                    .flatten
                                                    .include?(payment_method)
    end

    def payload_hash
      @payload_hash ||= payload.map { |obj| [obj.code, obj.value] }.to_h
    end

    def invalid_payload(attr)
      raise InvalidPayloadError,
            I18n.t('errors.messages.withdrawal.invalid_payload',
                   attr: attr.humanize(capitalize: false))
    end

    def invalid_payment_method
      raise InvalidPaymentMethodError,
            I18n.t('errors.messages.withdrawal.invalid_payment_method',
                   payment_method: payment_method.humanize)
    end

    def create_withdrawal!
      ::Withdrawal.create(entry_request: entry_request,
                          details: payload_hash)
    end
  end
end
