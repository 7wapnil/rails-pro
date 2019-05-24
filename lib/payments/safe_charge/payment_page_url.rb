module Payments
  module SafeCharge
    class PaymentPageUrl < ApplicationService
      include ::Payments::Methods

      API_VERSION = '4.0.0'.freeze

      def initialize(transaction)
        @transaction = transaction
      end

      def call
        "#{base_url}?#{query}"
      end

      private

      def base_url
        @base_url ||= ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
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
          encoding: Encoding::UTF_8.to_s,
          time_stamp: Time.zone.now.strftime('%Y-%m-%d.%H:%M:%S'),
          currency: currency_code,
          userid: @transaction.customer.id,
          productId: @transaction.id,
          user_token_id: @transaction.customer.id,
          item_name_1: item_name,
          item_number_1: @transaction.id,
          item_amount_1: @transaction.amount,
          item_quantity_1: 1,
          total_amount: @transaction.amount,
          first_name: @transaction.customer.first_name,
          last_name: @transaction.customer.last_name,
          email: @transaction.customer.email,
          phone1: @transaction.customer.phone,
          dateOfBirth: customer_date_of_birth,
          address1: @transaction.customer.address.street_address,
          city: @transaction.customer.address.city,
          country: @transaction.customer.address.country, # TODO: Take from db
          state: @transaction.customer.address.state, # TODO: Take from db
          zip: @transaction.customer.address.zip_code,
          isNative: 1,
          payment_method: provider_method_name(@transaction.method),
          payment_method_mode: 'filter',
          success_url: notification_url(:success),
          error_url: notification_url(:fail),
          back_url: notification_url(:cancel),
          pending_url: notification_url(:pending),
          notify_url: notification_url(:notification)
        }
      end

      def item_name
        "Deposit #{amount} to your #{currency_code} wallet on ArcaneBet"
      end

      def amount
        @transaction.amount
      end

      def currency_code
        @transaction.currency.code
      end

      def customer_date_of_birth
        @transaction.customer.date_of_birth&.strftime('%Y-%m-%d')
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

      def notification_url(res)
        "http://localhost:3000/payments/safe_charge/notification?result=#{res}"
      end
    end
  end
end
