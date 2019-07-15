# frozen_string_literal: true

module Payments
  module SafeCharge
    class DepositDetailsService < ApplicationService
      include ::Payments::SafeCharge::Methods

      def initialize(entry_request:, field:)
        @entry_request = entry_request
        @field = field
      end

      def call
        entry_request.deposit.update(details: payment_details)
      end

      private

      attr_reader :entry_request, :field

      def payment_details
        { IDENTIFIERS_MAP[entry_request.mode] => field }
      end
    end
  end
end
