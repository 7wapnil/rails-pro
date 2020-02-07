# frozen_string_literal: true

module GaEvents
  class SuccesfulPayment < ApplicationService
    def initialize(payee:, payment_processor:)
      @payee = payee
      @payment_processor = payment_processor
    end

    def call
      Rails.logger.info(payload)

      tracker.event(payload)
    end

    private

    def payload
      {
        category: 'Payment',
        action: 'Succesful',
        label: @payment_processor,
        value: @payee
        # TODO: not sure if we need it yet
        # user_ip:
        # user_id:
      }
    end

    def tracker
      @tracker ||= Staccato.tracker('UA-129576627-1', nil, ssl: true)
    end
  end
end
