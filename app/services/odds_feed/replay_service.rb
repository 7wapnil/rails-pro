# frozen_string_literal: true

module OddsFeed
  class ReplayService < ApplicationService
    SCENARIOS = [
      FIRST = '1',
      SECOND = '2',
      THIRD = '3'
    ].freeze

    DEFAULT_SCENARIOS = [FIRST, SECOND, THIRD].freeze

    def initialize(scenario_id:)
      @scenario_id = scenario_id
    end

    def call
      raise 'Unknown scenario' unless DEFAULT_SCENARIOS.include?(scenario_id)

      load_events!
    end

    private

    attr_reader :scenario_id

    def load_events!
      puts 'Started adding events to queue'

      events.each { |event_id| add_to_queue(event_id) }

      puts 'Finished'
    end

    def events
      @events ||= scenario_class.new.event_ids
    end

    def scenario_class
      case scenario_id
      when FIRST then ::OddsFeed::Scenarios::First
      when SECOND then ::OddsFeed::Scenarios::Second
      when THIRD then ::OddsFeed::Scenarios::Third
      end
    end

    def add_to_queue(id)
      client.request(route(id), method: :put)
    end

    def client
      @client ||= ::OddsFeed::Radar::Client.instance
    end

    def route(id)
      query_params = { node_id: ENV['RADAR_MQ_NODE_ID'] }.to_query

      "/replay/events/#{id}?#{query_params}"
    end
  end
end
