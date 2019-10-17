# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Statuses
        OK = 'OK'
        APPROVED = 'APPROVED'
        SUCCESS = 'SUCCESS'
        FAIL = 'FAIL'
        DECLINED = 'DECLINED'
        ERROR = 'ERROR'
        PAYOUT_APPROVED = 'Approved'
        PENDING = 'PENDING'

        REDIRECTION_MAP = {
          OK => ::Payments::Webhooks::Statuses::SUCCESS,
          SUCCESS => ::Payments::Webhooks::Statuses::SUCCESS,
          FAIL => ::Payments::Webhooks::Statuses::FAILED
        }.freeze
      end
    end
  end
end
