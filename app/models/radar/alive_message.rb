module Radar
  class AliveMessage
    attr_accessor :product_id, :reported_at, :subscribed
    attr_reader :subscription_state

    alias_method 'subscribed?', :subscribed

    delegate :recover_subscription!, to: :subscription_state
    delegate :subscribed!, to: :subscription_state

    def initialize(product_id:, reported_at:, subscribed:)
      @product_id = product_id
      @subscription_state = producer.subscription_state
      @reported_at = reported_at
      @subscribed = subscribed
      Rails.logger.info "Producer #{product_id} is alive"
    end

    def self.from_hash(data)
      reported_at_timestamp =
        Time.zone.at(data['timestamp'].to_i).to_datetime
      product_id = data['product'].to_i
      is_subscribed = data['subscribed'] == '1'

      new(
        product_id: product_id,
        reported_at: reported_at_timestamp,
        subscribed: is_subscribed
      )
    end

    def producer
      Radar::Producer.find_by_id(@product_id)
    end

    def process!
      subscribed? ? process_subscribed_message : process_unsubscribed_message
    end

    private

    def process_subscribed_message
      subscribed!(reported_at)
      producer.clear_failure_flag!
      true
    end

    def process_unsubscribed_message
      producer.raise_failure_flag!
      recover_subscription!
      true
    end
  end
end
