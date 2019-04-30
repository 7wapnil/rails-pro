# frozen_string_literal: true

module Mts
  class ValidationMessagePublisherWorker < ApplicationWorker
    def perform(bet_id)
      bet = find_bet(bet_id)
      response = Publishers::BetValidation.publish!(bet: bet)

      raise unless response

      notify_betslip(bet)
    end

    private

    def find_bet(bet_id)
      Bet.find(bet_id)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound,
            I18n.t('errors.messages.nonexistent_bet', id: bet_id)
    end

    def notify_betslip(bet)
      WebSocket::Client.instance.trigger_bet_update(bet)
    end
  end
end
