module Radar
  class HeartbeatWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'critical'

    def perform(payload)
      data = Hash.from_xml(payload)
      raise(ArgumentError, 'wrong xml') unless data.include? 'alive'
      data = data['alive']
      Heartbeat::Service.call(
        client: OddsFeed::Radar::Client.new,
        product: data['product'].to_i,
        timestamp: Time.at(data['timestamp'].to_i).to_datetime,
        alive: data['subscribed'] == '1'
      )
    end
  end
end
