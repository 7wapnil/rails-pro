module OddsFeed
  class MessageHandler
    def initialize(payload, configuration: {})
      @payload = payload
      @configuration = configuration
    end

    def profiler
      return @profiler if @profiler.present?

      Rails.logger.warn('Profiler not present')
      nil
    end

    def handle
      raise NotImplementedError
    end
  end
end
