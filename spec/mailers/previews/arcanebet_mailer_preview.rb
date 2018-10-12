class ArcanebetMailerPreview < ActionMailer::Preview
  def account_activation_mail
    ArcanebetMailer
      .with(customer: FactoryBot.create(:customer))
      .account_activation_mail
  end
end
