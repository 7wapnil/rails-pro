module OddsFeed
  module Radar
    class SubscriptionRecovery < ApplicationService
      OLDEST_RECOVERY_AVAILABLE_IN_HOURS = 72

      include JobLogger

      attr_reader :product

      delegate :last_successful_subscribed_at, to: :product
      alias latest_subscribed_at last_successful_subscribed_at

      def initialize(product:)
        @product = product
      end

      def call
        log_job_message(:info, "Recovering #{@product.code} from #{@start_at}")
        raise 'Recovery rates reached' unless rates_available?

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

      def node_id
        ENV['RADAR_MQ_NODE_ID']
      end

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
        return oldest_recovery_at if use_max_available_recovery?

        latest_subscribed_at
      end

      def use_max_available_recovery?
        !latest_subscribed_at || latest_subscribed_at < oldest_recovery_at
      end

      def oldest_recovery_at
        OLDEST_RECOVERY_AVAILABLE_IN_HOURS.hours.ago
      end

      def api_client
        @api_client ||= Client.new
      end
    end
  end
end
