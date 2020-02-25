# frozen_string_literal: true

module Bets
  class PlacementEntryRequestForm
    include ActiveModel::Model

    attr_accessor :subject

    def validate!
      validate_status!
      validate_amount!
    end

    private

    def validate_status!
      return unless subject.failed?

      raise Bets::RequestFailedError,
            I18n.t('internal.errors.messages.entry_request_failed')
    end

    def validate_amount!
      return if subject.amount.negative?

      raise Bets::RegistrationError,
            I18n.t('errors.messages.real_money_not_negative_amount')
    end
  end
end
