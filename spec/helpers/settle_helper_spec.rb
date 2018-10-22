describe SettleHelper, type: :helper do
  it 'no settle for unexpected settle' do
    expect(helper.settle_badge(:not_won_lost_or_void))
      .to eq(nil)
  end

  it 'won settle' do
    bet = FactoryBot.create(:bet, :won)
    expect(helper.settle_badge(bet.settlement_status))
      .to include('badge-success')
    expect(helper.settle_badge(bet.settlement_status))
      .to include('Won')
  end

  it 'lost settle' do
    bet = FactoryBot.create(:bet, :lost)
    expect(helper.settle_badge(bet.settlement_status))
      .to include('badge-danger')
    expect(helper.settle_badge(bet.settlement_status))
      .to include('Lost')
  end

  it 'void settle' do
    bet = FactoryBot.create(:bet, :void)
    expect(helper.settle_badge(bet.settlement_status))
      .to include('badge-primary')
    expect(helper.settle_badge(bet.settlement_status))
      .to include('Void')
  end
end
