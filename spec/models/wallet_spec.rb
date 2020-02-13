# frozen_string_literal: true

describe Wallet do
  subject(:wallet) { described_class.new }

  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:currency) }
  it { is_expected.to have_many(:entries) }
  it { is_expected.to have_many(:customer_bonuses) }
  it { is_expected.to have_one(:customer_bonus) }
  it { is_expected.to have_one(:initial_customer_bonus) }

  it { is_expected.to delegate_method(:name).to(:currency).with_prefix }
  it { is_expected.to delegate_method(:code).to(:currency).with_prefix }

  describe '.primary' do
    let!(:currency) { create(:currency) }
    let(:wallet) { create(:wallet, currency: currency) }

    let!(:primary_currency) { create(:currency, :primary) }
    let!(:primary_wallet) { create(:wallet, currency: primary_currency) }

    it 'returns wallets with primary currency' do
      expect(described_class.primary).to match_array(primary_wallet)
    end
  end

  describe 'callbacks' do
    let!(:wallet) { create(:wallet) }

    it 'emits websocket event on update' do
      expect(WebSocket::Client.instance)
        .to receive(:trigger_wallet_update)
        .with(wallet)
      wallet.update(amount: 1000)
    end

    it 'emits websocket event on amount update only' do
      expect(WebSocket::Client.instance).not_to receive(:trigger_wallet_update)
      wallet.update(updated_at: Time.now)
    end
  end

  describe 'CustomerBonus associations' do
    let!(:primary_currency) { create(:currency, :primary) }
    let!(:wallet) { create(:wallet, currency: primary_currency) }

    before do
      create(:customer_bonus,
             wallet: wallet,
             customer: wallet.customer,
             status: 'initial')
      create(:customer_bonus,
             wallet: wallet,
             customer: wallet.customer,
             status: 'expired')
    end

    it 'returns expired bonus as #customer_bonus' do
      expect(wallet.customer_bonus.status).to eq('expired')
    end

    it 'returns initial bonus as #initial_customer_bonus' do
      expect(wallet.initial_customer_bonus.status).to eq('initial')
    end
  end
end
