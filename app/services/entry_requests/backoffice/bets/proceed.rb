# frozen_string_literal: true

module EntryRequests
  module Backoffice
    module Bets
      class Proceed < ApplicationService
        delegate :entry_request, to: :bet
        delegate :customer, to: :bet

        def initialize(bet, params)
          @bet = bet
          @comment = params[:comment]
          @status = params[:settlement_status]
          @initiator = params[:initiator]
        end

        def call
          raise_unprocessed_bet! unless bet.placement_entry
          raise_update_to_current_state! unless new_status?

          case status
          when Bet::WON
            proceed_won_bet
          when Bet::VOIDED
            proceed_void_bet
          when Bet::LOST
            proceed_lost_bet
          else
            raise_invalid_status!
          end
        end

        private

        attr_reader :bet, :comment, :status, :initiator

        def raise_unprocessed_bet!
          raise ::Bets::InvalidStatusError,
                I18n.t('errors.messages.bets.unprocessed')
        end

        def new_status?
          bet.settlement_status != status
        end

        def raise_update_to_current_state!
          raise ::Bets::InvalidStatusError,
                I18n.t('errors.messages.bets.unchanged_status', status: status)
        end

        def proceed_won_bet
          log_creating EntryRequests::Backoffice::Bets::Won.call(**bet_params)
        end

        def proceed_void_bet
          EntryRequests::Backoffice::Bets::Voided
            .call(**bet_params)
            .each(&method(:log_creating))
        end

        def proceed_lost_bet
          EntryRequests::Backoffice::Bets::Lost
            .call(**bet_params)
            .each(&method(:log_creating))
        end

        def raise_invalid_status!
          raise ::Bets::InvalidStatusError,
                I18n.t('errors.messages.bets.invalid_status',
                       status: status)
        end

        def bet_params
          {
            bet: bet,
            initiator: initiator,
            comment: comment
          }
        end

        def log_creating(request)
          initiator.log_event(:entry_request_created, request, customer)
        end
      end
    end
  end
end
