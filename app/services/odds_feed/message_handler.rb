# frozen_string_literal: true

module OddsFeed
  class MessageHandler
    include ::OddsFeed::Radar::Timestampable

    def initialize(payload, configuration: {})
      @payload = payload
      @configuration = configuration
    end

    def handle
      raise NotImplementedError
    end

    protected

    attr_reader :payload, :configuration
  end
end
