# frozen_string_literal: true

module Customers
  module Summaries
    class BalanceUpdateWorker < ApplicationWorker
      def perform(day, entry_id)
        entry = Entry.find(entry_id)

        Customers::Summaries::UpdateBalance.call(day: day, entry: entry)
      rescue StandardError => error
        log_job_message(
          :error,
          message: 'Error on customer summary calculation for balances',
          day: day,
          entry_id: entry_id,
          error_object: error
        )
      end
    end
  end
end
