# frozen_string_literal: true

module Mts
  class CancellationResponseHandler < ApplicationService
    include JobLogger

    def initialize(message:)
      @message = JSON.parse(message)
    end

    def call
      successful_status_code? ? successful_bet_cancel : unsuccessful_bet_cancel

      refund!
    end

    private

    attr_reader :message

    def status_code
      @status_code ||= message.dig('result', 'reason', 'code')
    end

    def successful_status_code?
      status_code == ::Mts::Codes::SUCCESSFUL_CODE
    end

    def status
      ::Mts::Codes::CANCELLATION_ERROR_CODES[status_code]
    end

    def bet
      @bet ||= Bet.find_by!(validation_ticket_id: message['result']['ticketId'])
    rescue ActiveRecord::RecordNotFound
      error_message = I18n.t('errors.messages.nonexistent_bet')
      log_job_message(:error,
                      message: error_message,
                      id: message['result']['ticketId'])
      raise SilentRetryJobError,
            "#{error_message}. Id: #{message['result']['ticketId']}"
    end

    def successful_bet_cancel
      bet.cancelled!
    end

    def refund!
      refund = EntryRequests::Factories::Refund.call(entry: bet.entry)

      EntryRequests::RefundWorker.perform_async(refund.id)
    end

    def unsuccessful_bet_cancel
      bet.finish_external_cancellation_with_rejection!(
        I18n.t("errors.messages.mts.#{status}"),
        code: Bets::Notification::MTS_CANCELLATION_ERROR
      )

      log_job_message(:error,
                      message: I18n.t("errors.messages.mts.#{status}"),
                      bet_id: bet.id)
    end
  end
end
