class ArcanebetMailerPreview < ActionMailer::Preview
  def email_verification_mail
    ArcanebetMailer
      .with(customer: FactoryBot.create(:customer))
      .email_verification_mail
  end
end
