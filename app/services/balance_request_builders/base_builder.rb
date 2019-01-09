module BalanceRequestBuilders
  class BaseBuilder < ApplicationService
    def initialize(entry_request)
      @entry_request = entry_request
    end

    def call
      build!
    end

    protected

    attr_accessor :entry_request

    def build!
      error_msg = "#{__method__} needs to be implemented in #{self.class}"
      raise NotImplementedError, error_msg
    end
  end
end
