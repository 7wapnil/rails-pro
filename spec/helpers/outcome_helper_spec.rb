describe OutcomeHelper, type: :helper do
  it 'pending outcome' do
    odd = FactoryBot.create(:odd, won: nil)
    expect(helper.outcome_badge(odd.won))
      .to include('badge-secondary')
    expect(helper.outcome_badge(odd.won))
      .to include('Pending')
  end

  it 'won outcome' do
    odd = FactoryBot.create(:odd, won: true)
    expect(helper.outcome_badge(odd.won))
      .to include('badge-success')
    expect(helper.outcome_badge(odd.won))
      .to include('Won')
  end

  it 'lost outcome' do
    odd = FactoryBot.create(:odd, won: false)
    expect(helper.outcome_badge(odd.won))
      .to include('badge-danger')
    expect(helper.outcome_badge(odd.won))
      .to include('Lost')
  end
end
