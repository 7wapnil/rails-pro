# frozen_string_literal: true

class TrackPaymentEvent < ApplicationService
  def initialize(payee:, payment_processor:)
    @payee = payee
    @payment_processor = payment_processor
  end

  def call
    payload = {
      category: 'Payment',
      action: 'Succesful',
      label: @payment_processor,
      value: @payee
      # user_ip:
      # user_id:
    }

    Rails.logger.info(payload)
    tracker.event(payload)
  end

  private

  def tracker
    @tracker ||= Staccato.tracker('UA-129576627-1', nil, ssl: true)
  end
end
