class ArcanebetMailerPreview < ActionMailer::Preview
  def account_activation_mail
    ArcanebetMailer
      .with(customer: Customer.find(3610))
      .account_activation_mail
  end
end
