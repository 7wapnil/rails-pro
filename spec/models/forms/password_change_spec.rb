describe Forms::PasswordChange do
  it { should validate_presence_of(:existing_password) }
  it { should validate_presence_of(:new_password) }
  it { should validate_presence_of(:new_password_confirmation) }

  it { should validate_confirmation_of(:new_password) }

  it do
    should validate_length_of(:new_password)
      .is_at_least(6)
      .is_at_most(32)
  end
end
