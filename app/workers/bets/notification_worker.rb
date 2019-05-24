# frozen_string_literal: true

module Bets
  class NotificationWorker < ApplicationWorker
    DELAY = 1

    def perform(bet_id)
      bet = Bet.find(bet_id)

      sleep(DELAY)

      WebSocket::Client.instance.trigger_bet_update(bet)
    end
  end
end
