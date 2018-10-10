class ArcanebetMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: 'ArcaneBet'

  def account_activation_mail
    @customer = params[:customer]
    mail(to: @customer.email, subject: 'Activate you account')
  end
end
