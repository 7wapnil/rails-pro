describe Wallet do
  it { should belong_to(:customer) }
  it { should belong_to(:currency) }
  it { should have_many(:balances) }
  it { should have_many(:entries) }

  it { should delegate_method(:name).to(:currency).with_prefix }
  it { should delegate_method(:code).to(:currency).with_prefix }

  it do
    should validate_numericality_of(:amount)
      .is_greater_than_or_equal_to(0)
      .with_message(I18n.t('errors.messages.with_instance.not_negative',
                           instance: I18n.t('entities.wallet')))
  end
end
