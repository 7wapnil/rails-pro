# frozen_string_literal: true

class CustomerActivityMailer < ApplicationMailer
  def suspicious_login(login)
    customer = find_person(login)
    change_password_url = "#{domain}?changePassword=1"

    warn_suspicious_login(login) unless customer

    smtpapi_mail(
      template(__method__, customer.locale),
      customer.email,
      'changePasswordUrl': change_password_url
    )
  end

  def reset_password_mail(raw_token)
    customer = params[:customer]
    reset_password_url = "#{domain}/reset_password/#{raw_token}"

    smtpapi_mail(
      template(__method__, customer.locale),
      customer.email,
      'fullName':         customer.full_name,
      'resetPasswordUrl': reset_password_url
    )
  end

  private

  def domain
    ENV['FRONTEND_URL']
  end

  def find_person(login)
    @person = Customer.find_for_authentication(login: login) ||
              User.find_for_authentication(email: login)
  end

  def warn_suspicious_login(login)
    Rails.logger.warn(
      "Try to send suspicious login email to unpersisted person: `#{login}`."
    )
  end
end
