describe Balance do
  subject(:balance) { described_class.new }

  it { is_expected.to belong_to(:wallet) }
  it { is_expected.to have_many(:balance_entries) }
  # it { should define_enum_for :kind }

  it do
    expect(balance).to validate_numericality_of(:amount)
      .is_greater_than_or_equal_to(0)
      .with_message(I18n.t('errors.messages.with_instance.not_negative',
                           instance: I18n.t('entities.balance')))
  end
end
