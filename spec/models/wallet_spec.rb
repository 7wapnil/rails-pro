describe Wallet do
  subject(:wallet) { described_class.new }

  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:currency) }
  it { is_expected.to have_many(:balances) }
  it { is_expected.to have_many(:entries) }

  it { is_expected.to delegate_method(:name).to(:currency).with_prefix }
  it { is_expected.to delegate_method(:code).to(:currency).with_prefix }

  it do
    expect(wallet).to validate_numericality_of(:amount)
      .is_greater_than_or_equal_to(0)
      .with_message(I18n.t('errors.messages.with_instance.not_negative',
                           instance: I18n.t('entities.wallet')))
  end

  describe '.primary' do
    let!(:currency) { create(:currency) }
    let(:wallet) { create(:wallet, currency: currency) }

    let!(:primary_currency) { create(:currency, :primary) }
    let!(:primary_wallet) { create(:wallet, currency: primary_currency) }

    it 'returns wallets with primary currency' do
      expect(described_class.primary).to match_array(primary_wallet)
    end
  end
end
