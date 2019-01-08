module OddsFeed
  module Radar
    class SnapshotCompleteHandler < RadarMessageHandler
      def handle
        snapshot_complete_payload = (@payload['snapshot_complete'])
        product_id = snapshot_complete_payload['product'].to_i
        producer = ::Radar::Producer.find(product_id)
        request_id = snapshot_complete_payload['request_id'].to_i
        correct_snapshot_id = producer.recovery_snapshot_id == request_id
        raise 'Unknown snapshot completed' unless correct_snapshot_id

        producer.recovery_completed!
      end
    end
  end
end
