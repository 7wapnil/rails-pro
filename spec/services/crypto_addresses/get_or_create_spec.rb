# frozen_string_literal: true

describe ::CryptoAddresses::GetOrCreate do
  include_context 'crypto_deposit_transaction'

  subject { described_class.call(transaction) }

  context 'crypto address already exist' do
    it 'does not generate new address' do
      expect_any_instance_of(Payments::Crypto::CoinsPaid::Client)
        .not_to receive(:generate_address)

      subject
    end

    it 'returns correct crypto address' do
      expect(subject).to eq(wallet.crypto_address.address)
    end
  end

  context 'crypto address does not exist yet' do
    let(:wallet) do
      create(:wallet, :crypto, customer: customer)
    end
    let(:address) { Faker::Bitcoin.address }

    it 'invokes generation of new address' do
      expect_any_instance_of(Payments::Crypto::CoinsPaid::Client)
        .to receive(:generate_address)

      subject
    end

    it 'invokes crypto address generation service' do
      allow_any_instance_of(Payments::Crypto::CoinsPaid::Client)
        .to receive(:generate_address).and_return(address)

      expect { subject }.to change(CryptoAddress, :count).by(1)
    end

    it 'returns crypto address' do
      allow_any_instance_of(Payments::Crypto::CoinsPaid::Client)
        .to receive(:generate_address).and_return(address)

      expect(subject).to eq(address)
    end
  end
end
