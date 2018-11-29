module OddsFeed
  module Radar
    class EventStatusService < ApplicationService
      def initialize
        @match_status = OddsFeed::Radar::MatchStatusMappingService.new
      end

      def call(payload)
        @event_id = payload[:event_id]
        @payload = payload[:data]

        @payload.nil? ? no_payload_result : result
      end

      private

      def no_payload_result
        {
          id: complex_id,
          status_code: nil,
          status: nil,
          score: nil,
          time: nil,
          period_scores: [],
          finished: false
        }
      end

      def result
        {
          id: complex_id,
          status_code: @payload['match_status'],
          status: @match_status.call(@payload['match_status']),
          score: process_score!(@payload),
          time: process_time!,
          period_scores: process_periods!,
          finished:
            !@payload['results'].nil? && !@payload['results']['result'].nil?
        }
      end

      def process_score!(payload)
        return nil unless payload['home_score'] && payload['away_score']

        "#{payload['home_score']}:#{payload['away_score']}"
      end

      def process_time!
        @payload.dig('clock', 'match_time')
      end

      def process_periods!
        return [] unless @payload['period_scores']

        if @payload['period_scores']['period_score'].is_a? Hash
          [process_single_period!(
            @payload['period_scores']['period_score']
          )]
        else
          @payload['period_scores']['period_score'].map do |period_score|
            process_single_period!(period_score)
          end
        end
      end

      def process_single_period!(period)
        {
          id: complex_id(period),
          score: process_score!(period),
          status_code: period['match_status_code'],
          status: @match_status.call(period['match_status_code'])
        }
      end

      def complex_id(period = nil)
        @event_id.to_i * 1000 +
          (period ? period['match_status_code'].to_i : 0)
      end
    end
  end
end
