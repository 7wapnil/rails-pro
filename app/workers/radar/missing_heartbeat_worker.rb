module Radar
  class MissingHeartbeatWorker < ApplicationWorker
    def perform
      Radar::Producer::RADAR_AVAILABLE_PRODUCER_IDS.each do |producer_id|
        state = OddsFeed::Radar::ProducerSubscriptionState.new(producer_id)

        state.recover_subscription! if state.subscription_report_expired?
      end
    end
  end
end
