# frozen_string_literal: true

module Payments
  module SafeCharge
    # rubocop:disable Metrics/ClassLength
    class PaymentUrlValidator < ApplicationService
      BOOLEAN_FIELDS = %i[isNative].freeze
      BOOLEAN_OPTIONS = [0, 1, '0', '1'].freeze
      MANDATORY_FIELDS = %i[
        merchant_id merchant_site_id version time_stamp currency
        user_token_id item_name_1 item_number_1 item_amount_1
        item_quantity_1 total_amount checksum
      ].freeze

      def initialize(url:, query_hash:)
        @url = url
        @query = OpenStruct.new(query_hash)
        @fields = query.to_h.keys
      end

      def call
        raise error('Payment url is not provided.') if url.blank?

        check_mandatory_fields!
        check_encoding!
        check_currency!
        check_amount!

        raise error('time_stamp has wrong format.') unless time_stamp_valid?
        raise error('dateOfBirth has wrong format.') unless date_of_birth_valid?

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
          "Fields are required: #{missing_mandatory_fields.join(', ')}."
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

        raise error("`#{query.encoding}` is invalid encoding type.")
      end

      def check_currency!
        return if currency_available?

        raise error("`#{query.currency}` currency is not supported.")
      end

      def currency_available?
        ::SafeCharge::Currency::AVAILABLE_CURRENCY_LIST.include?(query.currency)
      end

      def check_amount!
        return if amounts_positive?

        raise error('Amount has to be positive.')
      end

      def amounts_positive?
        query.total_amount.to_f.positive? && query.item_amount_1.to_f.positive?
      end

      def time_stamp_valid?
        Time
          .strptime(query.time_stamp, PaymentPageUrl::TIMESTAMP_FORMAT)
          .present?
      rescue ArgumentError, TypeError
        false
      end

      def date_of_birth_valid?
        query.dateOfBirth.nil? ||
          Date.strptime(query.dateOfBirth,
                        PaymentPageUrl::DATE_OF_BIRTH_FORMAT).present?
      rescue ArgumentError, TypeError
        false
      end

      def check_boolean_fields!
        return unless invalid_boolean_fields.any?

        raise error(
          "Fields have to be 0 or 1: #{invalid_boolean_fields.join(', ')}."
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
        raise error 'Provided country is not supported.' unless valid_country?
      end

      def valid_country?
        !query.country ||
          ::SafeCharge::Country::AVAILABLE_COUNTRIES.include?(query.country)
      end

      def check_state!
        raise error 'Provided state is not supported.' unless valid_state?
      end

      def valid_state?
        query.country.blank? ||
          available_states.include?(query.state) ||
          (available_states.empty? && query.state.nil?)
      end

      def available_states
        @available_states ||=
          ::SafeCharge::State::AVAILABLE_STATES[query.country].to_a
      end

      def validate_checksum!
        return if Digest::SHA256.hexdigest(checksum_string) == query.checksum

        raise error 'Checksum is corrupted.'
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
