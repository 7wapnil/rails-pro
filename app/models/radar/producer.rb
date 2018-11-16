module Radar
  class Producer
    RADAR_AVAILABLE_PRODUCERS = [
      { radar_id: 1, code: :live },
      { radar_id: 3, code: :prematch }
    ].freeze

    attr_reader :radar_id, :code

    delegate :recover_subscription!, to: :subscription_state

    class << self
      def radar_ids
        RADAR_AVAILABLE_PRODUCERS.map { |producer| producer[:radar_id] }
      end

      def codes
        RADAR_AVAILABLE_PRODUCERS.map { |producer| producer[:code] }
      end

      def find_by_id(id)
        new(
          RADAR_AVAILABLE_PRODUCERS
            .detect { |producer| producer[:radar_id] == id }
        )
      end

      def find_by_code(code)
        new(
          RADAR_AVAILABLE_PRODUCERS
            .detect { |producer| producer[:code] == code }
        )
      end

      def available_producers
        RADAR_AVAILABLE_PRODUCERS.map { |args| new(args) }
      end

      def failure_flag_keys
        available_producers.map(&:failure_flag_key)
      end
    end

    def initialize(radar_id:, code:)
      raise ArgumentError unless self.class.radar_ids.include? radar_id
      raise ArgumentError unless self.class.codes.include? code

      @radar_id = radar_id
      @code = code
    end

    def failure_flag_key
      (code.to_s + '_odds_feed_offline').to_sym
    end

    def subscription_state
      OddsFeed::Radar::ProducerSubscriptionState.new(radar_id)
    end

    def raise_failure_flag!
      ApplicationState.instance.enable_flag(failure_flag_key)
    end

    def clear_failure_flag!
      ApplicationState.instance.disable_flag(failure_flag_key)
    end

    def check_subscription_expiration
      return unless subscription_state.subscription_report_expired?

      subscription_state.recover_subscription!
      raise_failure_flag!
    end
  end
end
