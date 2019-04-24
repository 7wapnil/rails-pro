module EventsManager
  class BaseEntityLoader < ApplicationService
    include EventsManager::Logger

    attr_writer :options

    def initialize(external_id, options = {})
      @external_id = external_id
      @options = options
    end

    def call
      raise NotImplementedError
    end

    protected

    def api_client
      @api_client ||= OddsFeed::Radar::Client.new
    end
  end
end
