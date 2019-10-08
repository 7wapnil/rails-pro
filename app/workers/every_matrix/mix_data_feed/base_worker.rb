# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class BaseWorker < ApplicationWorker
      sidekiq_options queue: :every_matrix_mix_data_feed

      def perform(row)
        payload = JSON.parse(row)

        handler_class.call(payload)
      end

      protected

      def handler_class
        raise NotImplementedError, 'Implement #handler_class method'
      end
    end
  end
end
