describe OddsFeed::MarketGenerator do
  let(:payload) do
    Nori.new.parse(file_fixture('odds_change_message.xml').read)
  end
  let(:event) { create(:event, external_id: 'sr:match:1234') }
  let(:markets_data) { payload['odds_change']['odds']['market'] }

  before do
    create(:market_template, external_id: '47')
  end

  it 'should generate new market if not exists in db'

  it 'should update market if exists in db'
end
