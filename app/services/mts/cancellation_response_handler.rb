# frozen_string_literal: true

module Mts
  class CancellationResponseHandler < ApplicationService
    include JobLogger

    def initialize(message:)
      @message = JSON.parse(message)
    end

    def call
      EntryRequests::BetCancellationWorker
        .perform_async(refund_entry_request.id, status_code)
    rescue ActiveRecord::RecordNotFound => error
      log_job_error(error)
      raise SilentRetryJobError,
            "#{error_message}. Id: #{message['result']['ticketId']}"
    end

    private

    attr_reader :message

    def refund_entry_request
      EntryRequests::Factories::Refund.call(entry: bet.entry)
    end

    def bet
      @bet ||= Bet.find_by!(validation_ticket_id: message['result']['ticketId'])
    end

    def status_code
      @status_code ||= message.dig('result', 'reason', 'code')
    end

    def log_job_error(error)
      log_job_message(:error, message: error_message,
                              id: message['result']['ticketId'],
                              error_object: error)
    end

    def error_message
      I18n.t('errors.messages.nonexistent_bet')
    end
  end
end
