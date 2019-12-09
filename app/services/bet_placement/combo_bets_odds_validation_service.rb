# frozen_string_literal: true

module BetPlacement
  class ComboBetsOddsValidationService < ApplicationService
    RULES = %i[event competitor].freeze

    def initialize(odd_ids)
      @odd_ids = odd_ids
    end

    def call
      odds.map do |odd|
        messages = error_messages(odd).compact

        OpenStruct.new(
          odd_id: odd.id,
          valid?: messages.none?,
          error_messages: messages
        )
      end
    end

    private

    attr_reader :odd_ids

    def odds
      @odds ||= Odd.where(id: odd_ids)
                   .includes(:market, :event, :competitors)
    end

    def error_messages(odd)
      RULES.map do |rule|
        next unless offences[rule].member?(odd.id)

        I18n.t("bets.notifications.conflicting_#{rule}")
      end
    end

    def offences
      @offences ||= RULES.each_with_object({}) do |rule, accumulator|
        accumulator[rule] = disallowed_odds(rule)
      end
    end

    def disallowed_odds(key)
      grouped_odds[key].values
                       .select(&method(:not_single?))
                       .flatten
    end

    def grouped_odds
      @grouped_odds ||= odds.each_with_object(store, &method(:group_odds))
    end

    def not_single?(group)
      group.length > 1
    end

    def store
      Hash.new do |hash, key|
        hash[key] = Hash.new do |sub_hash, sub_key|
          sub_hash[sub_key] = []
        end
      end
    end

    def group_odds(odd, accumulator)
      accumulator[:event][odd.event.id] << odd.id

      odd.competitors.each do |competitor|
        accumulator[:competitor][competitor.id] << odd.id
      end
    end
  end
end
