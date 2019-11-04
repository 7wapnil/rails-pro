# frozen_string_literal: true

module OddsFeed
  module Radar
    class SnapshotCompleteHandler < RadarMessageHandler
      def handle
        producer.with_lock do
          return invalid_snapshot_id! unless recovery_id_match?

          producer.complete_recovery!
        end
      end

      private

      def producer
        @producer ||= ::Radar::Producer.find(scrap_field('product'))
      end

      def scrap_field(key)
        payload['snapshot_complete'][key]
      end

      def recovery_id_match?
        producer.recovery_snapshot_id == request_id
      end

      def request_id
        @request_id ||= scrap_field('request_id').to_i
      end

      def invalid_snapshot_id!
        raise ::Radar::UnknownSnapshotError, 'Out-dated snapshot completed'
      rescue ::Radar::UnknownSnapshotError => e
        log_job_message(:error,
                        message: e.message,
                        producer_id: producer.id,
                        producer_state: producer.state,
                        producer_request_id: producer.recovery_snapshot_id,
                        payload_request_id: request_id,
                        error_object: e)
      end
    end
  end
end
