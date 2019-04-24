class ArcanebetMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: 'ArcaneBet'

  def suspicious_login(login)
    @person = find_person(login)

    warn_suspicious_login(login) unless @person

    mail(
      to:      @person.email,
      subject: I18n.t('mailers.arcanebet_mailer.suspicious_login.subject')
    )
  end

  def account_verification_mail
    @person = params[:customer]
    mail(
      to:      @person.email,
      subject: I18n.t('mailers.arcanebet_mailer.verification_mail.subject')
    )
  end

  def email_verification_mail
    domain = ENV['FRONTEND_URL']
    @customer = params[:customer]
    @verification_url =
      "#{domain}/email_verification/#{@customer.email_verification_token}"

    mail(
      to:      @customer.email,
      subject: I18n.t('mailers.arcanebet_mailer.email_verification.subject')
    )
  end

  private

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
