# frozen_string_literal: true

module Payments
  class NotificationsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def create
      Rails.logger.debug(message: 'Notification received', params: params)
      render plain: ::Payments::Notifications::Create.call(params)
    rescue StandardError => e
      Rails.logger.error(message: 'Notification error', error: e.message)
      render plain: "Standard errors: #{e.message}"
      # redirect_to return_customer_url(:failed, e.message)
    end
  end
end
