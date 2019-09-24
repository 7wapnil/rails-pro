# frozen_string_literal: true

describe BalanceCalculations::Deposit do
  subject do
    described_class.call(
      amount,
      currency,
      customer_bonus.reload,
      no_bonus: no_bonus
    )
  end

  let!(:primary_currency) { create(:currency, :primary) }
  let(:amount) { 200 }
  let(:max_deposit_bonus) { 20 }
  let(:customer) { create(:customer) }
  let(:wallet) do
    create(:wallet, customer: customer, currency: primary_currency)
  end
  let(:currency) { wallet.currency }

  let!(:customer_bonus) do
    create(:customer_bonus,
           customer: customer,
           wallet: wallet,
           percentage: 50,
           max_deposit_match: 1000)
  end
  let(:no_bonus) { nil }

  it 'calculates real money amount' do
    expect(subject[:real_money_amount]).to eq(amount)
  end

  it 'calculates bonus money amount' do
    expect(subject[:bonus_amount]).to eq(100)
  end

  it "returns 'max_deposit_match' when bonus amount is greater than allowed" do
    customer_bonus.update_attributes(max_deposit_match: max_deposit_bonus)

    expect(subject[:bonus_amount]).to eq(max_deposit_bonus)
  end

  it "returns 0 when deposit amount is less than bonus 'min_deposit'" do
    min_deposit = amount + 1
    customer_bonus.update_attributes(min_deposit: min_deposit)

    expect(subject[:bonus_amount]).to be_zero
  end

  context 'when `no_bonus` passed' do
    let(:no_bonus) { true }

    it 'returns 0' do
      customer_bonus.update_attributes(max_deposit_match: max_deposit_bonus)

      expect(subject[:bonus_amount]).to be_zero
    end
  end

  context 'with exchange_rate == 2' do
    let(:exchange_rate) { 2 }
    let(:non_primary_currency) do
      create(:currency, code: 'USD', exchange_rate: exchange_rate)
    end
    let(:currency) { non_primary_currency }
    let(:customer_bonus) do
      create(:customer_bonus,
             customer: customer,
             wallet: wallet,
             percentage: 100,
             max_deposit_match: max_deposit_bonus)
    end

    it 'corrects the max_deposit_bonus with the currency exchange_rate' do
      expect(subject[:bonus_amount]).to eq(max_deposit_bonus * exchange_rate)
    end
  end
end
