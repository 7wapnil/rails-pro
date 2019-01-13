shared_examples 'entries splitting with bonus' do
  it 'creates single bonus balance entry request' do
    attrs = {
      amount: bonus_amount,
      kind: Balance::BONUS
    }

    expect {}.to have_balance_entry_request
      .with_attributes(attrs)
      .count(1)
  end

  it 'creates single balance entry for bonus money' do
    expect {}.to have_balance_entry
      .with_attributes(amount: bonus_amount)
      .count(1)
  end

  it 'creates single real money balance entry request' do
    attrs = {
      amount: real_money_amount,
      kind: Balance::REAL_MONEY
    }

    expect {}.to have_balance_entry_request
      .with_attributes(attrs)
      .count(1)
  end

  it 'creates single balance entry for real money' do
    expect {}.to have_balance_entry
      .with_attributes(amount: real_money_amount)
      .count(1)
  end

  it 'creates only 2 balance entries' do
    expect {}.to have_balance_entry.count(2)
  end
end

shared_examples 'entries splitting without bonus' do
  it 'creates single real money balance entry request' do
    attrs = {
      amount: real_money_amount,
      kind: Balance::REAL_MONEY
    }

    expect {}.to have_balance_entry_request
      .with_attributes(attrs)
      .count(1)
  end

  it 'creates single balance entry for real money' do
    expect {}.to have_balance_entry
      .with_attributes(amount: real_money_amount)
      .count(1)
  end

  it "don't create bonus balance entry request" do
    expect {}.not_to have_balance_entry_request
      .with_attributes(kind: Balance::BONUS)
  end

  it 'creates only 1 balance entry' do
    expect {}.to have_balance_entry.count(1)
  end
end
