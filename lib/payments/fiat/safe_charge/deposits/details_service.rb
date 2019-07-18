# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        class DetailsService < ApplicationService
          include ::Payments::Fiat::SafeCharge::Methods

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
  end
end
