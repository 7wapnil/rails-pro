# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Deposits
        # rubocop:disable Metrics/ClassLength
        class CallbackHandler < Handlers::DepositCallbackHandler
          include Currencies::Crypto
          include Statuses

          MODE_MAP = {
            TBTC => EntryRequest::BITCOIN,
            BTC => EntryRequest::BITCOIN
          }.freeze

          def call
            return if pending?
            return if proceeded_transaction?

            create_deposit_entry_request
            return cancel_entry_request if cancelled?
            return create_deposit_entry! if confirmed?

            unknown_status!
          end

          private

          attr_accessor :entry_request

          delegate :min_deposit, to: :customer_bonus

          def pending?
            status == NOT_CONFIRMED
          end

          def proceeded_transaction?
            customer
              .entry_requests
              .deposit
              .find_by(mode: MODE_MAP[response['crypto_address']['currency']],
                       external_id: response['id'])
              .present?
          end

          def create_deposit_entry_request
            @entry_request = EntryRequests::Factories::Deposit.call(
              transaction: deposit_transaction,
              customer_bonus: valid_customer_bonus
            )
          end

          def deposit_transaction
            @deposit_transaction ||= ::Payments::Transactions::Deposit.new(
              method: ::Payments::Methods::BITCOIN,
              customer: customer,
              currency_code: currency_code,
              amount: converted_amount,
              external_id: response['id'].to_s
            )
          end

          def customer
            @customer ||=
              Customer.find(response['crypto_address']['foreign_id'])
          end

          def currency_code
            CURRENCY_CONVERTING_MAP[response['crypto_address']['currency']]
          end

          def converted_amount
            multiply_amount(response['currency_received']['amount'].to_f)
          end

          def valid_customer_bonus
            customer_bonus if valid_entry_for_customer_bonus?
          end

          def customer_bonus
            @customer_bonus ||= customer
                                .wallets
                                .joins(:currency)
                                .find_by(currencies: { code: currency_code })
                                &.customer_bonus
          end

          def valid_entry_for_customer_bonus?
            return unless customer_bonus&.initial?

            min_deposit.present? && converted_amount >= min_deposit
          end

          def cancelled?
            status == CANCELLED
          end

          def status
            @status ||= response['status']
          end

          def cancel_entry_request
            ga.track_event(deposit_failure(message))

            entry_request.register_failure!(message)
            fail_related_entities
          end

          def message
            case status
            when CONFIRMED
              I18n.t('payments.deposits.coins_paid.statuses.confirmed')
            when NOT_CONFIRMED
              I18n.t('payments.deposits.coins_paid.statuses.not_confirmed')
            when CANCELLED
              I18n.t('payments.deposits.coins_paid.statuses.cancelled')
            end
          end

          def confirmed?
            status == CONFIRMED
          end

          def create_deposit_entry!
            return if entry_request.succeeded?

            ga.track_event(deposit_success(entry_request.amount))

            entry_request.deposit.update(details: payment_details)
            ::EntryRequests::DepositService.call(entry_request: entry_request)
          end

          def payment_details
            { address: deposit_transaction.wallet.crypto_address.address }
          end

          def unknown_status!
            message =
              I18n.t('payments.deposits.coins_paid.errors.unknown_status',
                     status: status)
            error_message =
              "#{message} for entry request with id #{entry_request.id}"

            ga.track_event deposit_failure(message)

            entry_request.register_failure!(message)
            fail_related_entities

            raise ::Payments::GatewayError, error_message
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
