describe OddsFeed::Radar::MarketGenerator do
  let(:market_payload) do
    data = Hash.from_xml(file_fixture('odds_change_message.xml').read)
    data['odds_change']['odds']['market']
  end
  let(:chosen_market) { nil }
  let(:event) { create(:event, external_id: 'sr:match:1234') }
  subject do
    transpiler = OddsFeed::Radar::Transpiler.new(event, '123')
    allow(transpiler).to receive(:transpile).and_return('transpiler value')
    subject = OddsFeed::Radar::MarketGenerator.new(event, chosen_market)
    allow(subject).to receive(:transpiler).and_return(transpiler)
    subject
  end

  before do
    payload = {
      outcomes: [
        { 'id': '1' },
        { 'id': '2' }
      ]
    }.deep_stringify_keys

    create(:market_template, external_id: '123',
                             name: 'Template name',
                             payload: payload)
  end

  context 'market with outcomes' do
    let(:chosen_market) { market_payload[3] }
    let(:external_id) { 'sr:match:1234:123' }

    it 'generates new market if not exists in db' do
      subject.generate
      market = Market.find_by(external_id: external_id)
      expect(market).not_to be_nil
    end

    it 'updates market if exists in db' do
      market = create(:market, external_id: external_id)
      subject.generate
      updated_market = Market.find_by(external_id: external_id)
      expect(updated_market.updated_at).not_to eq(market.updated_at)
    end

    it 'sets appropriate status for market' do
      [
        { status: '-1', result: 'suspended' },
        { status: '0', result: 'inactive' },
        { status: '1', result: 'active' }
      ].each do |expectation|
        chosen_market['status'] = expectation[:status]
        subject.generate
        market = Market.find_by(external_id: external_id)
        expect(market.status).to eq(expectation[:result])
      end
    end

    it 'creates odds if not exist in db' do
      subject.generate
      expect(Odd.find_by(external_id: "#{external_id}:1")).not_to be_nil
      expect(Odd.find_by(external_id: "#{external_id}:2")).not_to be_nil
    end

    it 'updates odds if exist in db' do
      create(:odd, external_id: "#{external_id}:1", value: 1.0)
      create(:odd, external_id: "#{external_id}:2", value: 1.0)

      subject.generate
      expect(Odd.find_by(external_id: "#{external_id}:1").value).to eq(1.3)
      expect(Odd.find_by(external_id: "#{external_id}:2").value).to eq(1.7)
    end
  end
end
