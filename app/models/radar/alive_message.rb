module Radar
  class AliveMessage
    attr_accessor :product_id, :reported_at, :subscribed

    def intialize(product_id:, reported_at:, subscribed:)
      @product_id = product_id
      @reported_at = reported_at
      @subscribed = subscribed
    end

    def self.from_hash(data); end

    def save!; end

    def subscribed?; end
  end
end
