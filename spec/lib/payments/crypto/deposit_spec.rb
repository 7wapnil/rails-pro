# frozen_string_literal: true

describe Payments::Crypto::Deposit do
  subject { described_class.call(transaction) }

  let(:customer) { create(:customer, :ready_to_bet, type: :crypto) }
  let(:bonus_code) { nil }

  def transaction
    @transaction ||= ::Payments::Transactions::Deposit.new(
      method: Payments::Methods::BITCOIN,
      customer: customer,
      currency_code: customer.wallet.currency.code,
      amount: rand(10..100),
      bonus_code: bonus_code
    )
  end

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

    it 'does not create customer bonus' do
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
