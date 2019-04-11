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
      return snapshot_not_exists! unless market.previous_status

      { previous_status: nil, status: market.previous_status }
    end

    def snapshot_not_exists!
      raise "There is no status snapshot for market #{market.external_id}!"
    end
  end
end
