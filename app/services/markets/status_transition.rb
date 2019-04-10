# frozen_string_literal: true

module Markets
  class StatusTransition < ApplicationService
    def initialize(market:, status: nil, persist: false)
      @market = market
      @status = status
      @persist = persist
    end

    def call
      persist? ? update_market : market.assign_attributes(status_attributes)

      market.status
    end

    private

    attr_reader :market, :status, :persist

    def persist?
      persist.present?
    end

    def update_market
      market.update_columns(status_attributes)
    end

    def status_attributes
      return new_status_attributes if status

      build_rollback_attributes!
    end

    def new_status_attributes
      { previous_status: market.status_was, status: status }
    end

    def build_rollback_attributes!
      raise 'There is no status snapshot!' unless market.previous_status

      { previous_status: nil, status: market.previous_status }
    end
  end
end
