# frozen_string_literal: true

describe Payments::Crypto::CoinsPaid::Deposits::RequestHandler do
  subject { described_class.call(transaction) }

  include_context 'crypto_deposit_transaction'

  context 'with crypto address' do
    it 'does not generate new address' do
      expect_any_instance_of(Payments::Crypto::CoinsPaid::Client)
        .not_to receive(:generate_address)

      subject
    end

    it 'returns crypto address' do
      expect(subject).to eq(wallet.crypto_address.address)
    end
  end

  context 'without crypto address' do
    let(:address) { Faker::Bitcoin.address }
    let!(:wallet) do
      create(:wallet, :crypto_btc, customer: customer)
    end
    let(:client_double) { double }

    it 'does not generate new address' do
      expect_any_instance_of(Payments::Crypto::CoinsPaid::Client)
        .to receive(:generate_address)

      subject
    end

    it 'returns crypto address' do
      allow(Payments::Crypto::CoinsPaid::Client)
        .to receive(:new).and_return(client_double)
      allow(client_double)
        .to receive(:generate_address).and_return(address)

      expect(subject).to eq(address)
    end
  end
end
