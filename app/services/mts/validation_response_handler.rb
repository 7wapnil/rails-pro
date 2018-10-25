module Mts
  class ValidationResponseHandler < ApplicationService
    attr_accessor :response

    def initialize(response)
      @response = Mts::Messages::ValidationResponse.new(response)
    end

    def call
      @response.bets.each do |bet|
        bet.finish_external_validation_with_rejection! if @response.rejected?
        bet.finish_external_validation_with_acceptance! if @response.accepted?
      end
    end
  end
end
