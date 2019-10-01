# frozen_string_literal: true

module Customers
  class BetsController < ApplicationController
    find :customer, by: :customer_id
    find :bet

    def update
      EntryRequests::Backoffice::Bets::Proceed.call(@bet, bet_params)

      flash[:success] = t('messages.bets.flash')
      redirect_to bets_customer_path(@customer)
    rescue Bets::InvalidStatusError, Bets::AuthorizeWalletEntryError => error
      flash[:error] = error.message
      redirect_back fallback_location: root_path
    end

    private

    def bet_params
      params
        .require(:bet)
        .permit(:settlement_status)
        .merge(
          initiator: current_user,
          customer: @customer,
          comment: params[:bet][:entry_request][:comment]
        )
    end
  end
end
