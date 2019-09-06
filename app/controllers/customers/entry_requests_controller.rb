# frozen_string_literal: true

module Customers
  class EntryRequestsController < ApplicationController
    find :customer, by: :customer_id

    def create
      EntryRequests::BackofficeEntryRequestService.call(payload_params)

      flash[:success] = t('messages.entry_request.flash')
      redirect_to account_management_customer_path(@customer)
    rescue Wallets::ValidationError, EntryRequests::ValidationError => error
      flash[:error] = error.message
      redirect_back fallback_location: root_path
    end

    private

    def payload_params
      params
        .require(:entry_request)
        .permit(:currency_id, :amount, :kind, :mode, :comment)
        .merge(initiator: current_user, customer: @customer)
    end
  end
end
