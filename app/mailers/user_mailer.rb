# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def negative_balance_bet_placement
    customer = params[:customer]
    domain = ENV['APP_HOST']
    customer_url = "#{domain}/customers/#{customer.id}"
    receiver = ENV['ADMIN_NOTIFY_MAIL'] || 'contact@arcanebet.com'

    smtpapi_mail(
      template(__method__, I18n.default_locale),
      receiver,
      'customerName': customer.full_name,
      'customerUrl': customer_url
    )
  end
end
