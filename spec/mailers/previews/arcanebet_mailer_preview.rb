class ArcanebetMailerPreview < ActionMailer::Preview
  def email_verification_mail
    ApplicationMailer
      .with(customer: FactoryBot.create(:customer))
      .email_verification_mail
  end
end
