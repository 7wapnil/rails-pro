# frozen_string_literal: true

module Mts
  class CancellationResponseWorker < ApplicationWorker
    def perform(message)
      CancellationResponseHandler.call(message: message)
    end
  end
end
