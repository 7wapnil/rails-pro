# frozen_string_literal: true

module Customers
  module Summaries
    class UpdateWorker < ApplicationWorker
      def perform(day, attributes)
        summary = find_or_create_summary!(day)

        ActiveRecord::Base.transaction do
          summary.lock!

          Customers::Summaries::Update.call(summary, attributes)
        end
      rescue StandardError => error
        log_job_message(
          :error,
          message: 'Error on customer summary calculation',
          day: day,
          attributes: attributes,
          error_object: error
        )
      end

      private

      def find_or_create_summary!(day)
        Customers::Summary.find_or_create_by(day: day)
      rescue ActiveRecord::RecordNotUnique
        Customers::Summary.all.reload.find_by!(day: day)
      end
    end
  end
end
