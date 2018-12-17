module OddsFeed
  module Radar
    class SubscriptionRecovery < ApplicationService
      include JobLogger

      PRODUCTS_MAP = {
        1 => :liveodds,
        3 => :pre
      }.freeze

      attr_accessor :product_id, :start_at

      def initialize(product_id:, start_at: nil)
        @product_id = product_id
        @start_at = start_at
      end

      def call
        log_job_message(:info, "Recovering #{@product_id} from #{@start_at}")
        return unless product_available?
        return unless rates_available?

        response = api_client.product_recovery_initiate_request(
          product_code: code,
          after: start_at
        )
        return unless response['response']['response_code'] == 'ACCEPTED'

        write_previous_recovery_timestamp(Time.zone.now.to_i)
      end

      def rates_available?
        last_call = previous_recovery_timestamp
        return true unless last_call

        Time.at(last_call) < Time.zone.now - 30.seconds
      end

      private

      def api_client
        @api_client ||= Client.new
      end

      def product_available?
        PRODUCTS_MAP.include? product_id
      end

      def code
        PRODUCTS_MAP[product_id]
      end

      def write_previous_recovery_timestamp(timestamp)
        Rails.cache.write(previous_recovery_call_key, timestamp)
      end

      def previous_recovery_timestamp
        Rails.cache.read(previous_recovery_call_key)
      end

      def previous_recovery_call_key
        'radar:last_recovery_call'
      end
    end
  end
end
