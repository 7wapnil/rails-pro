module Radar
  class AliveMessage
    attr_accessor :product_id, :reported_at, :subscribed

    def initialize(product_id:, reported_at:, subscribed:)
      @product_id = product_id
      @reported_at = reported_at
      @subscribed = subscribed
    end

    def self.from_hash(data)
      message = new(
        product_id: data['product_id'].to_i,
        reported_at: Time.at(data['reported_at'].to_i).to_datetime,
        subscribed: data['subscribed'] == '1'
      )
      message
    end

    def save!
      return unless subscribed?
      store_last_successful_alive!
    end

    alias_method 'subscribed?', :subscribed

    private

    def store_last_successful_alive!
      current_timestamp = Rails.cache.read(last_success_at).to_i
      timestamp = reported_at.to_i
      timestamp_expired = current_timestamp > timestamp

      return if timestamp_expired
      Rails.cache.write(
        last_success_at,
        timestamp.to_i
      )
    end

    def last_success_at
      last_successful_alive_message(product_id: product_id)
    end

    def last_successful_alive_message(product_id:)
      "radar:last_successful_alive_message:#{product_id}"
    end
  end
end
