describe BalanceCalculations::Deposit do
  let(:amount) { 200 }
  let(:max_deposit_bonus) { 20 }
  let(:customer) { create(:customer) }

  let!(:customer_bonus) do
    create(:customer_bonus,
           customer: customer,
           percentage: 50,
           max_deposit_match: 1000)
  end

  let(:wallet) { instance_double('Wallet', customer: customer) }

  it 'calculates real money amount' do
    real = described_class.call(customer_bonus, amount)[:real_money]

    expect(real).to eq(amount)
  end

  it 'calculates bonus money amount' do
    bonus = described_class.call(customer_bonus, amount)[:bonus]

    expect(bonus).to eq(100)
  end

  it "returns 'max_deposit_match' when bonus amount is greater than allowed" do
    customer_bonus.update_attributes(max_deposit_match: max_deposit_bonus)
    bonus = described_class.call(customer_bonus, amount)[:bonus]

    expect(bonus).to eq(max_deposit_bonus)
  end

  it "returns 0 when deposit amount is less than bonus 'min_deposit'" do
    min_deposit = amount + 1
    customer_bonus.update_attributes(min_deposit: min_deposit)
    bonus = described_class.call(customer_bonus, amount)[:bonus]

    expect(bonus).to be_zero
  end
end
