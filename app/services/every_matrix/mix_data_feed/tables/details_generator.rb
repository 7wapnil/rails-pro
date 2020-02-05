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
          details = EveryMatrix::TableDetails
                    .find_or_initialize_by(play_item_id: table.id)

          details.update!(update_params.compact)
        end

        private

        attr_reader :data, :table

        def update_params
          {
            is_vip_table: property['isVIPTable'],
            is_open: data['isOpen'],
            is_seats_unlimited: property['isSeatsUnlimited'],
            is_bet_behind_available: property['isBetBehindAvailable'],
            currency_limits: property['limits'],
            always_opened: opening_time['is24HoursOpen'],
            start_time: opening_time['startTime'],
            end_time: opening_time['endTime']
          }
        end

        def property
          @property ||= data['property']
        end

        def opening_time
          @opening_time ||= data['openingTime']
        end
      end
    end
  end
end
