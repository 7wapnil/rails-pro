module Mts
  class ValidationResponse
    SUPPORTED_VALIDATION_RESPONSE_VERSION = '2.1'.freeze

    attr_reader :message

    def initialize(input_json)
      @message = parse(input_json)
      raise NotImplementedError unless version ==
                                       SUPPORTED_VALIDATION_RESPONSE_VERSION
    end

    # getters

    def version
      @message.version
    end

    # getters.validation_result

    def rejected?
      result.status == 'rejected'
    end

    def result
      @message.result
    end

    private

    def parse(json)
      JSON.parse(json, object_class: OpenStruct)
    end
  end
end
