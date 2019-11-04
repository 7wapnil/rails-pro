# frozen_string_literal: true

module Radar
  class Producer < ApplicationRecord
    include StateMachines::Radar::ProducerStateMachine

    LIVE_PROVIDER_ID = 1
    LIVE_PROVIDER_CODE = 'liveodds'

    PREMATCH_PROVIDER_ID = 3
    PREMATCH_PROVIDER_CODE = 'pre'

    self.table_name = 'radar_producers'

    has_many :events
    has_many :markets

    class << self
      def live
        find_by(code: LIVE_PROVIDER_CODE)
      end

      def prematch
        find_by(code: PREMATCH_PROVIDER_CODE)
      end

      def recovery_disabled?
        Rails.env.development? &&
          !ActiveRecord::Type::Boolean.new.cast(ENV['RADAR_RECOVERY_ENABLED'])
      end
    end

    def live?
      code == LIVE_PROVIDER_CODE
    end

    def prematch?
      code == PREMATCH_PROVIDER_CODE
    end

    def to_s
      code
    end
  end
end
