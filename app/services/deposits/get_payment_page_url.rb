# frozen_string_literal: true

module Deposits
  # rubocop:disable Metrics/ClassLength
  class GetPaymentPageUrl < ApplicationService
    API_VERSION = '4.0.0'

    TIME_STAMP_FORMAT = '%Y-%m-%d.%H:%M:%S'
    DATE_OF_BIRTH_FORMAT = '%Y-%m-%d'
    ITEM_QUANTITY = 1

    def initialize(entry_request:, **extra_query_params)
      @entry_request = entry_request
      @extra_query_params = extra_query_params
    end

    delegate :customer_id, :customer, :currency, to: :entry_request

    delegate :first_name, :last_name, :email, :address, :phone,
             to: :customer, prefix: true

    delegate :street_address, :city, :country_code, :zip_code,
             to: :customer_address, allow_nil: true, prefix: true

    def call
      validate!

      "#{url}?#{query}"
    end

    private

    attr_reader :entry_request, :extra_query_params

    def validate!
      PaymentUrlValidator.call(url: url, query_hash: query_hash_with_checksum)
    end

    def url
      @url ||= ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
    end

    def query
      URI.encode_www_form(query_hash_with_checksum)
    end

    def query_hash_with_checksum
      @query_hash_with_checksum ||= query_hash.merge(checksum: checksum)
    end

    def query_hash # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      @query_hash ||= {
        merchant_id: ENV['SAFECHARGE_MERCHANT_ID'],
        merchant_site_id: ENV['SAFECHARGE_MERCHANT_SITE_ID'],
        version: API_VERSION,
        encoding: extra_query_params.fetch(:encoding) { Encoding::UTF_8.to_s },
        time_stamp: time_stamp,
        currency: extra_query_params.fetch(:currency_code) { currency.code },
        userid: customer_id,
        productId: entry_request.id,
        user_token_id: customer_id,
        item_name_1: extra_query_params.fetch(:item_name_1) { item_name },
        item_number_1: entry_request.id,
        item_amount_1: amount,
        item_quantity_1: ITEM_QUANTITY,
        total_amount: amount,
        first_name: customer_first_name,
        last_name: customer_last_name,
        email: customer_email,
        phone1: customer_phone,
        dateOfBirth: customer_date_of_birth,
        address1: customer_address_street_address,
        city: customer_address_city,
        country: customer_address_country_code, # TODO: Take directly from db
        state: customer_address_state_code, # TODO: Take directly from db
        zip: customer_address_zip_code,
        isNative: extra_query_params.fetch(:isNative, 1),
        **url_parameters
      }
    end

    def amount
      @amount ||= BalanceEntryRequest
                  .real_money
                  .find_by!(entry_request_id: entry_request)
                  .amount
    end

    def url_parameters
      {
        success_url: ENV['SAFECHARGE_DEPOSIT_SUCCESS_URL'],
        error_url: ENV['SAFECHARGE_DEPOSIT_ERROR_URL'],
        pending_url: ENV['SAFECHARGE_DEPOSIT_PENDING_URL'],
        back_url: ENV['SAFECHARGE_DEPOSIT_BACK_URL'],
        notify_url: ENV['SAFECHARGE_DEPOSIT_NOTIFY_URL']
      }.reject { |_key, value| value.blank? }
    end

    def time_stamp
      return specified_time_stamp if specified_time_stamp.is_a?(String)

      specified_time_stamp&.strftime(TIME_STAMP_FORMAT)
    end

    def specified_time_stamp
      @specified_time_stamp ||= extra_query_params
                                .fetch(:time_stamp) { Time.zone.now }
    end

    def item_name
      "Deposit #{amount} to your #{currency.code} wallet " \
      'on ArcaneBet.'
    end

    # TODO: remove when states would be handled on back-end
    def customer_address_state_code
      customer_address.state_code if with_state?
    end

    def with_state?
      SafeCharge::State::AVAILABLE_STATES.key?(customer_address_country_code)
    end

    def customer_date_of_birth
      customer.date_of_birth&.strftime(DATE_OF_BIRTH_FORMAT)
    end

    def checksum
      Digest::SHA256.hexdigest(checksum_string)
    end

    def checksum_string
      [
        ENV['SAFECHARGE_SECRET_KEY'],
        *query_hash.values
      ].map(&:to_s).join
    end
  end
  # rubocop:enable Metrics/ClassLength
end
