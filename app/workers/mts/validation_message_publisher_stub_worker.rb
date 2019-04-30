# frozen_string_literal: true

module Mts
  class ValidationMessagePublisherStubWorker < ApplicationWorker
    DELAY_IN_SECONDS = 2

    def perform(bet_id)
      sleep(DELAY_IN_SECONDS)

      bet = find_bet(bet_id)
      bet.finish_external_validation_with_acceptance!
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
