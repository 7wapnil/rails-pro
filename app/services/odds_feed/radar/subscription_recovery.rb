module OddsFeed
  module Radar
    class SubscriptionRecovery < ApplicationService
      include JobLogger

      attr_accessor :product

      def initialize(product:)
        @product = product
      end

      def call
        log_job_message(:info, "Recovering #{@product.code} from #{@start_at}")
        raise 'Recovery rates reached' unless rates_available?

        node_id = ENV['RADAR_MQ_NODE_ID']
        requested_at = Time.zone.now
        request_id = requested_at.to_i

        request_recovery(node_id, request_id)
        update_product(node_id, request_id, requested_at)
      end

      def rates_available?
        last_call = ::Radar::Producer.last_recovery_call_at
        return true unless last_call

        minimal_delay_between_calls = 30.seconds

        last_call < Time.zone.now - minimal_delay_between_calls
      end

      private

      def request_recovery(node_id, request_id)
        response = api_client.product_recovery_initiate_request(
          product_code: product.code,
          after: recover_after,
          node_id: node_id,
          request_id: request_id
        )
        request_success = response['response']['response_code'] == 'ACCEPTED'
        raise 'Unsuccessful recovery' unless request_success
      end

      def update_product(node_id, request_id, requested_at)
        product.update(
          recover_requested_at: requested_at,
          recovery_snapshot_id: request_id,
          recovery_node_id: node_id
        )
      end

      def recover_after
        last_recorded_at = product.last_successful_subscribed_at
        oldest_recovery_at = 72.hours.ago
        return oldest_recovery_at unless last_recorded_at
        return oldest_recovery_at if last_recorded_at < oldest_recovery_at

        last_recorded_at
      end

      def api_client
        @api_client ||= Client.new
      end
    end
  end
end
