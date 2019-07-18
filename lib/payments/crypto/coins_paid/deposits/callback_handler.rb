# frozen_string_literal: true

module Payments
  module Crypto
    module CoinsPaid
      module Deposits
        # rubocop:disable Metrics/ClassLength
        class CallbackHandler < Handlers::DepositCallbackHandler
          include Statuses

          M_BTC_MULTIPLIER = 1000
          FINISH_STATES = %w[succeeded failed].freeze

          TBTC = 'TBTC'
          BTC = 'BTC'

          CURRENCIES_MAP = {
            TBTC => 'mTBTC',
            BTC => 'mBTC'
          }.freeze

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
            transaction = ::Payments::Transactions::Deposit.new(
              method: ::Payments::Methods::BITCOIN,
              customer: customer,
              currency_code: currency_code,
              amount: converted_amount,
              external_id: response['id'].to_s
            )
            @entry_request =
              ::Payments::Crypto::CoinsPaid::Deposits::RequestHandler
              .call(transaction: transaction,
                    customer_bonus: valid_customer_bonus)
          end

          def customer
            @customer ||=
              Customer.find(response['crypto_address']['foreign_id'])
          end

          def currency_code
            CURRENCIES_MAP[response['crypto_address']['currency']]
          end

          def converted_amount
            response['currency_received']['amount'].to_f * M_BTC_MULTIPLIER
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

            ::EntryRequests::DepositService.call(entry_request: entry_request)
          end

          def unknown_status!
            message =
              I18n.t('payments.deposits.coins_paid.errors.unknown_status',
                     status: status)
            error_message =
              "#{message} for entry request with id #{entry_request.id}"

            entry_request.register_failure!(message)
            fail_related_entities

            raise message: 'CoinsPaid deposit callback error',
                  error: error_message
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
