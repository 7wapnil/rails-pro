# frozen_string_literal: true

module OddsFeed
  module Radar
    class SnapshotCompleteHandler < RadarMessageHandler
      def handle
        return false unless producer.recovering?

        correct_snapshot_id = producer.recovery_snapshot_id == request_id
        return invalid_snapshot_id! unless correct_snapshot_id

        producer.recovery_completed!
      end

      private

      def producer
        @producer ||= ::Radar::Producer.find(product_id)
      end

      def product_id
        payload_body['product'].to_i
      end

      def payload_body
        payload['snapshot_complete']
      end

      def request_id
        payload_body['request_id'].to_i
      end

      def invalid_snapshot_id!
        raise Snapshots::UnknownSnapshotError, 'Unknown snapshot completed'
      rescue Snapshots::UnknownSnapshotError => e
        log_job_message(:error,
                        message: e.message,
                        error_object: e,
                        producer_request_id: producer.recovery_snapshot_id,
                        payload_request_id: request_id)

        raise SilentRetryJobError, e.message
      end
    end
  end
end
