class ArcanebetMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: 'ArcaneBet'

  def account_activation_mail
    @customer = params[:customer]
    domain = ENV['FRONTEND_URL']
    @activation_url = "#{domain}/activation/#{@customer.activation_token}"
    mail(to: @customer.email, subject: 'Activate you account')
  end
end
