# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      # rubocop:disable Metrics/ClassLength
      class PaymentUrlValidator < ApplicationService
        BOOLEAN_FIELDS = %i[isNative].freeze
        BOOLEAN_OPTIONS = [0, 1, '0', '1'].freeze
        MANDATORY_FIELDS = %i[
          merchant_id merchant_site_id version time_stamp currency
          user_token_id item_name_1 item_number_1 item_amount_1
          item_quantity_1 total_amount checksum payment_method
        ].freeze

        def initialize(url:, query_hash:)
          @url = url
          @query = OpenStruct.new(query_hash)
          @fields = query.to_h.keys
        end

        def call
          raise error('Payment url is not provided') if url.blank?

          check_mandatory_fields!
          check_encoding!
          check_currency!
          check_amount!

          raise error('time_stamp in wrong format') unless time_stamp_valid?
          raise error('dateOfBirth in wrong format') unless date_of_birth_valid?

          check_boolean_fields!
          check_address_fields!
          validate_checksum!

          true
        end

        private

        attr_reader :url, :query, :fields

        def error(message)
          ::SafeCharge::InvalidPaymentUrlError.new(message)
        end

        def check_mandatory_fields!
          return unless missing_mandatory_fields.any?

          raise error(
            "Fields are required: #{missing_mandatory_fields.join(', ')}"
          )
        end

        def missing_mandatory_fields
          @missing_mandatory_fields ||= MANDATORY_FIELDS - fields_with_value
        end

        def fields_with_value
          query.to_h.reject { |_k, value| value.blank? }.keys
        end

        def check_encoding!
          return if ::Encoding.name_list.include?(query.encoding)

          raise error("`#{query.encoding}` is invalid encoding type")
        end

        def check_currency!
          return if currency_available?

          raise input_error(I18n.t('errors.messages.currency_not_supported'))
        end

        def input_error(message)
          ::SafeCharge::InvalidInputError.new(message)
        end

        def currency_available?
          ::Payments::Fiat::SafeCharge::Currency::AVAILABLE_CURRENCY_LIST
            .fetch(query.payment_method, [])
            .include?(query.currency)
        end

        def check_amount!
          return if amounts_positive?

          raise input_error(I18n.t('errors.messages.amount_negative'))
        end

        def amounts_positive?
          query.total_amount.to_f.positive? &&
            query.item_amount_1.to_f.positive?
        end

        def time_stamp_valid?
          Time
            .strptime(
              query.time_stamp,
              Deposits::RequestHandler::TIMESTAMP_FORMAT
            ).present?
        rescue ArgumentError, TypeError
          false
        end

        def date_of_birth_valid?
          query.dateOfBirth.nil? ||
            Date.strptime(
              query.dateOfBirth,
              Deposits::RequestHandler::DATE_OF_BIRTH_FORMAT
            ).present?
        rescue ArgumentError, TypeError
          false
        end

        def check_boolean_fields!
          return unless invalid_boolean_fields.any?

          raise error(
            "Fields have to be 0 or 1: #{invalid_boolean_fields.join(', ')}"
          )
        end

        def invalid_boolean_fields
          @invalid_boolean_fields ||=
            (BOOLEAN_FIELDS & fields)
            .select { |field| BOOLEAN_OPTIONS.exclude?(query[field]) }
        end

        def check_address_fields!
          check_country!
          check_state!
        end

        def check_country!
          return if valid_country?

          raise input_error(I18n.t('errors.messages.country_not_supported'))
        end

        def valid_country?
          !query.country ||
            Country::AVAILABLE_COUNTRIES.fetch(query.payment_method, [])
                                        .include?(query.country)
        end

        def check_state!
          return if valid_state?

          raise input_error(I18n.t('errors.messages.state_not_supported'))
        end

        def valid_state?
          query.country.blank? ||
            available_states.include?(query.state) ||
            (available_states.empty? && query.state.nil?)
        end

        def available_states
          @available_states ||= State::AVAILABLE_STATES[query.country].to_a
        end

        def validate_checksum!
          return if Digest::SHA256.hexdigest(checksum_string) == query.checksum

          raise error 'Checksum is corrupted'
        end

        def checksum_string
          [
            ENV['SAFECHARGE_SECRET_KEY'],
            *query.to_h.except(:checksum).values
          ].map(&:to_s).join
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
