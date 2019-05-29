# frozen_string_literal: true

module OddsFeed
  module Radar
    class SubscriptionRecovery < ApplicationService
      MINIMAL_DELAY_BETWEEN_CALLS_IN_SECONDS = 30
      OLDEST_RECOVERY_AVAILABLE_IN_HOURS = 72

      RECOVERY_RATES_REACHED_MESSAGE = 'Recovery rates reached'
      UNSUCCESSFUL_RECOVERY_MESSAGE = 'Unsuccessful recovery'
      RECOVERY_REQUEST_INITIATED_MESSAGE = 'Recovery request initiated'

      include JobLogger

      attr_reader :product

      delegate :last_disconnection_at, to: :product

      def initialize(product:)
        @product = product
      end

      def call
        log_job_message(:info,
                        message: RECOVERY_REQUEST_INITIATED_MESSAGE,
                        producer_code: @product.code,
                        recovery_after: recover_after)
        unless rates_available?
          log_job_message(:error, RECOVERY_RATES_REACHED_MESSAGE)
          return false
        end

        requested_at = Time.zone.now
        request_id = requested_at.to_i

        request_recovery(node_id, request_id)
        update_product(node_id, request_id, requested_at)
      end

      def rates_available?
        last_call = ::Radar::Producer.last_recovery_call_at
        return true unless last_call

        last_call < MINIMAL_DELAY_BETWEEN_CALLS_IN_SECONDS.seconds.ago
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
        raise UNSUCCESSFUL_RECOVERY_MESSAGE unless response_success(response)
      end

      def response_success(response)
        response['response']['response_code'] == 'ACCEPTED'
      rescue StandardError
        false
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

        last_disconnection_at
      end

      def use_max_available_recovery?
        !last_disconnection_at || last_disconnection_at < oldest_recovery_at
      end

      def oldest_recovery_at
        OLDEST_RECOVERY_AVAILABLE_IN_HOURS.hours.ago
      end

      def api_client
        @api_client ||= ::OddsFeed::Radar::Client.instance
      end
    end
  end
end
