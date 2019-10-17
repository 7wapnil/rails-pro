# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        class ModeVerifier < ApplicationService
          include ::Payments::Fiat::SafeCharge::Methods

          def initialize(payment_method_code:, entry_request:)
            @payment_method_code = payment_method_code
            @entry_request = entry_request
          end

          def call
            unsupported_payment_method unless mode_from_code

            return if no_changes?

            entry_request.update(mode: mode_from_code)
          end

          private

          attr_reader :entry_request, :payment_method_code

          def mode_from_code
            @mode_from_code ||= PAYMENT_METHOD_MAP[payment_method_code]
          end

          def unsupported_payment_method
            entry_request.register_failure!(fail_message)

            raise NotImplementedError, fail_message
          end

          def no_changes?
            entry_request.mode == mode_from_code
          end

          def fail_message
            I18n.t(
              'errors.messages.unsupported_payment_method',
              code: payment_method_code
            )
          end
        end
      end
    end
  end
end
