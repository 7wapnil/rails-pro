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

  describe '#current_ratio' do
    let(:wallet) { create(:wallet) }
    let(:bonus_amount) { rand(1000.0) }
    let(:real_amount) { rand(1000.0) }
    let(:bonus_balance) { double('Balance', amount: bonus_amount) }
    let(:real_balance) { double('Balance', amount: real_amount) }

    before do
      allow(wallet).to receive(:bonus_balance).and_return(bonus_balance)
      allow(wallet).to receive(:real_money_balance).and_return(real_balance)
    end

    it 'returns current ratio' do
      expected_ratio = real_amount / (real_amount + bonus_amount)

      expect(wallet.current_ratio).to eq(expected_ratio)
    end

    it 'returns current ratio without bonus' do
      allow(wallet).to receive(:bonus_balance).and_return(nil)

      expect(wallet.current_ratio).to eq(1)
    end

    it 'returns nil when real balance is nil' do
      allow(wallet).to receive(:real_money_balance).and_return(nil)

      expect(wallet.current_ratio).to be_nil
    end
  end
end
