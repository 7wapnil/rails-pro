module Radar
  class AliveMessage
    attr_accessor :product_id, :reported_at, :subscribed
    attr_reader :subscription_state

    alias_method 'subscribed?', :subscribed

    delegate :recover_subscription!, to: :subscription_state

    def initialize(product_id:, reported_at:, subscribed:)
      @product_id = product_id
      @subscription_state =
        ::OddsFeed::Radar::ProducerSubscriptionState.new(product_id)
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

    def save
      @subscription_state.subscribed!(reported_at) if subscribed?
    end
  end
end
