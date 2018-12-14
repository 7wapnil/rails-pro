module Radar
  class Producer
    RADAR_AVAILABLE_PRODUCERS = [
      { radar_id: 1, code: :live },
      { radar_id: 3, code: :prematch }
    ].freeze

    attr_reader :radar_id, :code

    class << self
      def radar_ids
        RADAR_AVAILABLE_PRODUCERS.map { |producer| producer[:radar_id] }
      end

      def codes
        RADAR_AVAILABLE_PRODUCERS.map { |producer| producer[:code] }
      end

      def find_by_id(id)
        producer = RADAR_AVAILABLE_PRODUCERS
                   .detect { |el| el[:radar_id] == id.to_i }
        new(producer) unless producer.nil?
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
  end
end
