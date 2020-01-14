# frozen_string_literal: true

module Bets
  class PlacementError < StandardError
    attr_reader :bet, :odd_id

    def initialize(message, bet: nil, odd_id: nil)
      super(message)

      @bet = bet
      @odd_id = odd_id
    end
  end
end
