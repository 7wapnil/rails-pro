# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Deposits
        class UpdateDetails < ApplicationService
          include ::Payments::Fiat::SafeCharge::Methods

          def initialize(entry_request:, payment_option_id:)
            @entry_request = entry_request
            @payment_option_id = payment_option_id&.to_s
          end

          def call
            entry_request.deposit.update(details: payment_details)
          end

          private

          attr_reader :entry_request, :payment_option_id

          def payment_details
            find_identical_payment_details || build_new_payment_details
          end

          def find_identical_payment_details
            entry_request
              .customer
              .entry_requests
              .select('customer_transactions.details')
              .joins(:deposit, :entry)
              .deposit
              .succeeded
              .where.not(id: entry_request.id)
              .find_by(
                "customer_transactions.details->>'user_payment_option_id' = ?",
                payment_option_id
              )
              &.details
          end

          def build_new_payment_details
            {
              user_payment_option_id: payment_option_id,
              name: scrap_payment_option_name
            }
          end

          def scrap_payment_option_name
            user_payment_option_info[name_identifier] ||
              I18n.t("kinds.payment_methods.#{entry_request.mode}")
          end

          def user_payment_option_info
            ::Payments::Fiat::SafeCharge::Client
              .new(customer: entry_request.customer)
              .receive_user_payment_option(payment_option_id)
              .fetch('upoData', {})
          end

          def name_identifier
            NAME_IDENTIFIERS_MAP[entry_request.mode]
          end
        end
      end
    end
  end
end
