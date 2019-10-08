# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class HeartbeatWorker < ApplicationWorker
      sidekiq_options queue: :every_matrix_mix_data_feed, retry: 1

      ALIVE_DELAY = 20.seconds

      def perform
        connection_state.with_lock do
          break if connection_state.updated_at > ALIVE_DELAY.ago

          connection_state.dead!
        end
      end

      private

      def connection_state
        @connection_state ||= EveryMatrix::Connection.instance
      end
    end
  end
end
