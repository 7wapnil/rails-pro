module OddsFeed
  class MessageHandler
    def initialize(payload, profiler = nil, configuration: {})
      @payload = payload
      @configuration = configuration
      @profiler = profiler
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
