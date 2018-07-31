module Radar
  class AliveMessage
    attr_accessor :product_id, :reported_at, :subscribed

    alias_method 'subscribed?', :subscribed

    def initialize(product_id:, reported_at:, subscribed:)
      @product_id = product_id
      @reported_at = reported_at
      @subscribed = subscribed
    end

    def self.from_hash(data)
      new(
        product_id: data['product_id'].to_i,
        reported_at: Time.zone.at(data['reported_at'].to_i).to_datetime,
        subscribed: data['subscribed'] == '1'
      )
    end

    def save!
      store_last_successful_alive! if subscribed?
    end

    def recover!
      start_at = last_success_timestamp
      # binding.pry
      start_at = nil if Time.zone.at(start_at) < 72.hours.ago
      OddsFeed::Radar::SubscriptionRecovery
        .call(product_id: product_id, start_at: start_at)
    end

    private

    def store_last_successful_alive!
      timestamp = reported_at.to_i
      timestamp_expired = last_success_timestamp > timestamp
      return if timestamp_expired

      update_last_success_timestamp(timestamp)
    end

    def update_last_success_timestamp(timestamp)
      Rails.cache.write(last_success_at_key, timestamp)
    end

    def last_success_timestamp
      Rails.cache.read(last_success_at_key).to_i
    end

    def last_success_at_key
      last_successful_alive_message_key(product_id: product_id)
    end

    def last_successful_alive_message_key(product_id:)
      "radar:last_successful_alive_message:#{product_id}"
    end
  end
end
