# frozen_string_literal: true

module OddsFeed
  class PrepareScenario < ApplicationService
    SCENARIOS = [
      FIRST = '1',
      SECOND = '2',
      THIRD = '3'
    ].freeze
    DEFAULT_SCENARIOS = [FIRST, SECOND, THIRD].freeze

    def initialize(scenario_id: DEFAULT_SCENARIOS)
      @scenario_ids = Array.wrap(scenario_id).uniq.compact.map(&:to_s)
    end

    def call
      validate_scenario_id!

      clean_up_database!
      perform_scenarios
    end

    private

    attr_reader :scenario_ids

    def validate_scenario_id!
      excluded_scenarios = scenario_ids - SCENARIOS
      return if excluded_scenarios.blank?

      raise "Scenario \"#{excluded_scenarios.first}\" is not implemented yet!"
    end

    def clean_up_database!
      ::OddsFeed::Scenarios::PrepareDatabase.call
    end

    def perform_scenarios
      scenario_ids.each { |scenario_id| scenario_class(scenario_id).call }
    end

    def scenario_class(scenario_id)
      case scenario_id
      when FIRST then ::OddsFeed::Scenarios::First
      when SECOND then ::OddsFeed::Scenarios::Second
      when THIRD then ::OddsFeed::Scenarios::Third
      end
    end
  end
end
