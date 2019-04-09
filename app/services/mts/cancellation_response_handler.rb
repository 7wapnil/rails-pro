# frozen_string_literal: true

module Mts
  class CancellationResponseHandler < ApplicationService
    include JobLogger

    SUCCESSFUL_CODE = 1024

    TICKET_NOT_FOUND = 'ticket_not_found'
    INCONSISTENT_BOOKMAKER_CODE = 'inconsistent_bookmaker_code'
    LIVE_SELECTIONS = 'live_selections'
    CANCELLATION_TIME_EXPIRED = 'cancellation_time_expired'
    PRE_MATCH_SECTION = 'pre_match_section'
    CANCELLATION_OPTION_NOT_ACTIVE = 'cancellation_option_not_active'
    TICKET_ALREADY_SETTLED = 'ticket_already_settled'
    GENERIC_EXCEPTION = 'generic_exception'

    UNSUCCESSFUL_RESPONSE_STATUSES = {
      -2010 => TICKET_NOT_FOUND,
      -2011 => INCONSISTENT_BOOKMAKER_CODE,
      -2012 => LIVE_SELECTIONS,
      -2013 => CANCELLATION_TIME_EXPIRED,
      -2015 => PRE_MATCH_SECTION,
      -2016 => CANCELLATION_OPTION_NOT_ACTIVE,
      -2017 => TICKET_ALREADY_SETTLED,
      -999 => GENERIC_EXCEPTION
    }.freeze

    def initialize(message:)
      @message = JSON.parse(message)
    end

    def call
      successful_status_code? ? successful_bet_cancel : unsuccessful_bet_cancel

      entry_refund!
    end

    private

    attr_reader :message

    def status_code
      @status_code ||= message.dig('result', 'reason', 'code')
    end

    def successful_status_code?
      status_code == SUCCESSFUL_CODE
    end

    def status
      UNSUCCESSFUL_RESPONSE_STATUSES[status_code]
    end

    def bet
      @bet ||= Bet.find_by!(validation_ticket_id: message['result']['ticketId'])
    rescue ActiveRecord::RecordNotFound
      raise I18n.t('errors.messages.nonexistent_bet',
                   id: message['result']['ticketId'])
    end

    def successful_bet_cancel
      bet.cancelled!
    end

    def entry_refund!
      refund = EntryRequests::Factories::Refund.call(entry: bet.entry)

      EntryRequests::RefundWorker.perform_async(refund.id)
    end

    def unsuccessful_bet_cancel
      bet.pending_manual_cancellation!

      log_job_failure(message: unsuccessful_message)
    end

    def unsuccessful_message
      I18n.t("errors.messages.mts.#{status}", bet_id: bet.id)
    end
  end
end
