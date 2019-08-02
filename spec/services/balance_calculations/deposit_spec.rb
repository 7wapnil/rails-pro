# frozen_string_literal: true

describe BalanceCalculations::Deposit do
  let!(:primary_currency) { create(:currency, :primary) }

  let(:amount) { 200 }
  let(:max_deposit_bonus) { 20 }
  let(:customer) { create(:customer) }
  let(:wallet) { create(:wallet, customer: customer) }
  let(:currency) { wallet.currency }

  let!(:customer_bonus) do
    create(:customer_bonus,
           customer: customer,
           percentage: 50,
           max_deposit_match: 1000)
  end

  it 'calculates real money amount' do
    real = described_class.call(amount, currency, customer_bonus)[:real_money]

    expect(real).to eq(amount)
  end

  it 'calculates bonus money amount' do
    bonus = described_class.call(amount, currency, customer_bonus)[:bonus]

    expect(bonus).to eq(100)
  end

  it "returns 'max_deposit_match' when bonus amount is greater than allowed" do
    customer_bonus.update_attributes(max_deposit_match: max_deposit_bonus)
    bonus = described_class.call(amount, currency, customer_bonus)[:bonus]

    expect(bonus).to eq(max_deposit_bonus)
  end

  it "returns 0 when deposit amount is less than bonus 'min_deposit'" do
    min_deposit = amount + 1
    customer_bonus.update_attributes(min_deposit: min_deposit)
    bonus = described_class.call(amount, currency, customer_bonus)[:bonus]

    expect(bonus).to be_zero
  end

  it 'returns 0 when `no_bonus` passed' do
    customer_bonus.update_attributes(max_deposit_match: max_deposit_bonus)
    bonus = described_class.call(
      amount,
      currency,
      customer_bonus,
      no_bonus: true
    )[:bonus]

    expect(bonus).to be_zero
  end

  context 'with exchange_rate == 2' do
    let(:exchange_rate) { 2 }
    let(:non_primary_currency) do
      create(:currency, code: 'USD', exchange_rate: exchange_rate)
    end
    let(:customer_bonus) do
      create(:customer_bonus,
             customer: customer,
             percentage: 100,
             max_deposit_match: max_deposit_bonus)
    end

    it 'corrects the max_deposit_bonus with the currency exchange_rate' do
      bonus = described_class.call(
        amount,
        non_primary_currency,
        customer_bonus
      )[:bonus]

      expect(bonus).to eq(max_deposit_bonus / exchange_rate)
    end
  end
end
