module Radar
  class AliveMessage
    PRODUCT_ID_KEY = 'product'
    REPORTED_AT_KEY = 'timestamp'
    SUBSCRIBED_KEY = 'subscribed'

    attr_accessor :product_id, :reported_at, :subscribed

    alias_method 'subscribed?', :subscribed

    def initialize(product_id:, reported_at:, subscribed:)
      @product_id = product_id
      @reported_at = reported_at
      @subscribed = subscribed
    end

    def self.from_hash(data)
      raise unless valid_external_data?(data)

      reported_at_timestamp = Time.zone.at(data[REPORTED_AT_KEY].to_i).to_datetime
      product_id = data[PRODUCT_ID_KEY].to_i
      is_subscribed = (data[SUBSCRIBED_KEY] == '1')

      new(
        product_id: product_id,
        reported_at: reported_at_timestamp,
        subscribed: is_subscribed
      )
    end

    def save
      store_last_successful_alive! if subscribed?
    end

    def recover!
      start_at = last_success_timestamp
      start_at = nil if Time.zone.at(start_at) < 72.hours.ago
      OddsFeed::Radar::SubscriptionRecovery
        .call(product_id: product_id, start_at: start_at)
    end

    private

    def self.valid_external_data?(data)
      return false if data[PRODUCT_ID_KEY].nil?
      return false if data[REPORTED_AT_KEY].nil?
      return false if data[SUBSCRIBED_KEY].nil?
      return false unless data[PRODUCT_ID_KEY].to_i.to_s == data[PRODUCT_ID_KEY].to_s
      return false unless %w[0 1].include?(data[SUBSCRIBED_KEY])
      true
    end

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
