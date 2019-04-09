# frozen_string_literal: true

module Mts
  class ValidationResponseWorker < ApplicationWorker
    def perform(message)
      ValidationResponseHandler.call(message)
    end
  end
end
