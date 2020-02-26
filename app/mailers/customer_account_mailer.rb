# frozen_string_literal: true

class CustomerAccountMailer < ApplicationMailer
  def email_verification_mail
    customer = params[:customer]
    verification_url =
      "#{domain}/email_verification/#{customer.email_verification_token}"
    bonus_rules_url = "#{domain}/promotions/bonus-rules"

    smtpapi_mail(
      template(__method__, customer.locale),
      customer.email,
      'fullName':        customer.full_name,
      'verificationUrl': verification_url,
      'bonusRulesUrl':   bonus_rules_url
    )
  end

  def account_verification_mail
    customer = params[:customer]
    deposit_url = "#{domain}?depositState=1"

    smtpapi_mail(
      template(__method__, customer.locale),
      customer.email,
      'fullName':   customer.full_name,
      'depositUrl': deposit_url
    )
  end

  private

  def domain
    ENV['FRONTEND_URL']
  end
end
