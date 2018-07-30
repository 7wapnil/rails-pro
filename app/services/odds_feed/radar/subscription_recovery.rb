module OddsFeed
  module Radar
    class SubscriptionRecovery < ApplicationService
      attr_accessor :product_id, :start_at

      def initialize(product_id:, start_at: nil)
        @product_id = product_id
        @start_at = start_at
      end

      def call
        return unless rates_available?
        response = api_client.subscription_recovery(
          product_id: product_id,
          start_at: start_at
        )
        return unless response.code == 202
        write_previous_recovery_timestamp(Time.zone.now.to_i)
      end

      def api_client
        @api_client ||= Client.new
      end

      def rates_available?
        last_call = previous_recovery_timestamp
        return true unless last_call
        Time.at(last_call) < Time.zone.now - 30.seconds
      end

      private

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
