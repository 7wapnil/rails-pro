describe SettleHelper, type: :helper do
  it 'pending settle' do
    odd = FactoryBot.create(:odd, :unsettled)
    expect(helper.settle_badge(odd.settle))
      .to include('badge-secondary')
    expect(helper.settle_badge(odd.settle))
      .to include('Pending')
  end

  it 'won settle' do
    odd = FactoryBot.create(:odd, :settled_win)
    expect(helper.settle_badge(odd.settle))
      .to include('badge-success')
    expect(helper.settle_badge(odd.settle))
      .to include('Won')
  end

  it 'lost settle' do
    odd = FactoryBot.create(:odd, :settled_lost)
    expect(helper.settle_badge(odd.settle))
      .to include('badge-danger')
    expect(helper.settle_badge(odd.settle))
      .to include('Lost')
  end
end
