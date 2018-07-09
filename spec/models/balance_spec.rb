describe Balance do
  it_should_behave_like 'audit model', factory: :balance

  it { should belong_to(:wallet) }
  it { should have_many(:balance_entries) }
  it { is_expected.to define_enum_for :kind }

  it do
    should validate_numericality_of(:amount)
      .is_greater_than_or_equal_to(0)
      .with_message(I18n.t('errors.messages.with_instance.not_negative',
                           instance: I18n.t('entities.balance')))
  end
end
