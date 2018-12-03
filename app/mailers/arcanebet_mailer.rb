class ArcanebetMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: 'ArcaneBet'

  def account_activation_mail
    domain          = ENV['FRONTEND_URL']
    @customer       = params[:customer]
    @activation_url = "#{domain}/activation/#{@customer.activation_token}"

    mail(to: @customer.email, subject: 'Activate you account')
  end

  def suspicious_login(login)
    @person = find_person(login)

    warn_suspicious_login(login) unless @person

    mail(
      to:      @person.email,
      subject: I18n.t('mailers.arcanebet_mailer.suspicious_login.subject')
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
