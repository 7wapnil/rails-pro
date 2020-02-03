# frozen_string_literal: true

require 'sidekiq-scheduler'

class CleanUpBaseWorker < ApplicationWorker
  sidekiq_options queue: 'clean_up_data'

  MAX_ITERATIONS = 1_000
  BATCH_SIZE = 50_000

  def perform
    MAX_ITERATIONS.times do
      return if cmd_tuples < BATCH_SIZE
    end

    raise StandardError, 'Infinite loop without break condition'
  end

  def cmd_tuples
    ActiveRecord::Base.connection
                      .execute(delete_query)
                      .cmd_tuples
  end

  def delete_query
    raise NotImplementedError, 'Define delete query'
  end
end
