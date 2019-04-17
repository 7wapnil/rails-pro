module Scheduled
  class ExchangeRatesWorker < ApplicationWorker
    sidekiq_options queue: 'exchange_rates',
                    lock: :until_executed

    def perform
      Exchanger::RatesScraper.call
    end
  end
end
