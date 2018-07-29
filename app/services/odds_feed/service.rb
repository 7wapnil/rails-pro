module OddsFeed
  class Service < ApplicationService
    def initialize(_api_client, payload)
      msg = 'Service is deprecated, use Receiver instead'
      ActiveSupport::Deprecation.warn msg
      @payload = payload
    end

    def call
      receiver = Radar::OddsChangeHandler.new(@payload)
      receiver.handle
    end
  end
end
