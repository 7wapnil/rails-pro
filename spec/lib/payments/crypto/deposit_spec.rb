# frozen_string_literal: true

describe Payments::Crypto::Deposit do
  include_context('crypto_deposit_transaction')

  subject { described_class.call(transaction) }

  it 'generate deposit address' do
    expect_any_instance_of(Payments::Crypto::CoinsPaid::Provider)
      .to receive(:receive_deposit_address)

    subject
  end

  context 'without customer bonus' do
    it 'does not create customer bonus' do
      expect(CustomerBonuses::Create).not_to receive(:call)

      subject
    end
  end

  context 'with customer bonus' do
    let(:bonus_code) { create(:bonus).code }

    it 'create customer bonus' do
      allow_any_instance_of(Payments::Crypto::CoinsPaid::Provider)
        .to receive(:receive_deposit_address).and_return('address')

      expect(CustomerBonuses::Create).to receive(:call)

      subject
    end
  end

  context 'customer with active bonus' do
    let(:bonus_code) { create(:bonus).code }
    let!(:customer_bonus) do
      create(:customer_bonus, :active,
             customer: customer, wallet: customer.wallet)
    end

    it 'does not create customer bonus' do
      expect(CustomerBonuses::Create).not_to receive(:call)

      subject
    end
  end
end
