shared_examples 'entries splitting with bonus' do
  it 'creates single bonus balance entry request' do
    attrs = {
      amount: bonus_amount,
      kind: Balance::BONUS
    }

    expect(BalanceEntryRequest.where(attrs).count).to eq(1)
  end

  it 'creates single balance entry for bonus money' do
    expect(BalanceEntry.where(amount: bonus_amount).count).to eq(1)
  end

  it 'creates single real money balance entry request' do
    attrs = {
      amount: real_money_amount,
      kind: Balance::REAL_MONEY
    }

    expect(BalanceEntryRequest.where(attrs).count).to eq(1)
  end

  it 'creates single balance entry for real money' do
    expect(BalanceEntry.where(amount: real_money_amount).count).to eq(1)
  end

  it 'creates only 2 balance entries' do
    expect(BalanceEntry.count).to eq(2)
  end

  it 'creates only 2 balance entry requests' do
    expect(BalanceEntryRequest.count).to eq(2)
  end
end

shared_examples 'entries splitting without bonus' do
  it 'creates single real money balance entry request' do
    attrs = {
      amount: real_money_amount,
      kind: Balance::REAL_MONEY
    }

    expect(BalanceEntryRequest.where(attrs).count).to eq(1)
  end

  it 'creates single balance entry for real money' do
    expect(BalanceEntry.where(amount: real_money_amount).count).to eq(1)
  end

  it "don't create bonus balance entry request" do
    expect(BalanceEntryRequest.bonus.count).to be_zero
  end

  it 'creates only 1 balance entry' do
    expect(BalanceEntry.count).to eq(1)
  end

  it 'creates only 1 balance entry request' do
    expect(EntryRequest.count).to eq(1)
  end
end
