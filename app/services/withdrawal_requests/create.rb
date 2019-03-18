# frozen_string_literal: true

module WithdrawalRequests
  class Create < ApplicationService
    def initialize(entry_request:, payload:, payment_method:)
      @entry_request = entry_request
      @payload = payload
      @payment_method = payment_method
    end

    def call
      return failed_entry_request if entry_request.failed?

      validate_payload
      create_withdrawal_request!
    end

    private

    attr_reader :entry_request, :payload, :payment_method

    def failed_entry_request
      raise Withdrawals::WithdrawalError
    end

    def validate_payload
      invalid_payment_method unless valid_payment_method?

      required_fields.each(&method(:validate_field))
    end

    def required_fields
      SafeCharge::Withdraw::WITHDRAW_MODE_FIELDS[payment_method]
        .map { |detail| detail[:code] }
    end

    def validate_field(field)
      invalid_payload unless payload_hash[field.to_s].present?
    end

    def valid_payment_method?
      SafeCharge::Withdraw::AVAILABLE_WITHDRAW_MODES.include?(payment_method)
    end

    def payload_hash
      @payload_hash ||= payload.map { |a| [a.key, a.value] }.to_h
    end

    def invalid_payload
      raise InvalidPayloadError,
            I18n.t('errors.messages.withdrawal.invalid_payload')
    end

    def invalid_payment_method
      raise InvalidPaymentMethodError,
            I18n.t('errors.messages.withdrawal.invalid_payment_method')
    end

    def create_withdrawal_request!
      WithdrawalRequest.create(entry_request: entry_request,
                               payment_method: payment_method,
                               payment_details: payload_hash)
    end
  end
end
