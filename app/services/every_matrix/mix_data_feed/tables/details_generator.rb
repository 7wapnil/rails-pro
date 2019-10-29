# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    module Tables
      class DetailsGenerator < ApplicationService
        def initialize(data:, table:)
          @data = data
          @table = table
        end

        def call
          EveryMatrix::TableDetails.create!(
            play_item: table,
            is_vip_table: data['isVIPTable'],
            is_open: data['isOpen'],
            is_seats_unlimited: data['isSeatsUnlimited'],
            is_bet_behind_available: data['isBetBehindAvailable'],
            min_limit: min_limit,
            max_limit: max_limit
          )
        end

        private

        attr_reader :data, :table

        def min_limit
          data['min']
        end

        def max_limit
          data['max']
        end
      end
    end
  end
end
