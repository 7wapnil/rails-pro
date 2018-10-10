class ArcanebetMailer < ApplicationMailer
  default from: 'noreply@arcanebet.com',
          subject: 'ArcaneBet'

  def account_activation_mail
    @customer = params[:customer]
    recipient = %("#{@customer.full_name}" <#{@customer.email}>)
    mail(to: recipient, subject: 'Activate you account')
  end
end
