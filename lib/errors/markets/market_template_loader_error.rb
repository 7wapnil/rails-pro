module Markets
  class MarketTemplateLoaderError < StandardError
    attr_reader :external_id

    def initialize(message, external_id)
      @external_id = external_id
      super(message)
    end
  end
end
