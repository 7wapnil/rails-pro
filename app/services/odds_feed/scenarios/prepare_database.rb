# frozen_string_literal: true

module OddsFeed
  module Scenarios
    class PrepareDatabase < ApplicationService
      BATCH_SIZE = 500

      def call
        Event.in_batches(of: BATCH_SIZE, &:destroy_all)
        EventScope.delete_all
        CompetitorPlayer.delete_all
        Competitor.delete_all
        Player.delete_all
      end
    end
  end
end
