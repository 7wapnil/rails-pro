module OddsFeed
  module Radar
    class SnapshotCompleteHandler < RadarMessageHandler
      def handle
        return false unless producer.recovering?

        correct_snapshot_id = producer.recovery_snapshot_id == request_id
        raise 'Unknown snapshot completed' unless correct_snapshot_id

        producer.recovery_completed!
      end

      private

      def payload_body
        @payload['snapshot_complete']
      end

      def request_id
        payload_body['request_id'].to_i
      end

      def product_id
        payload_body['product'].to_i
      end

      def producer
        ::Radar::Producer.find(product_id)
      end
    end
  end
end
