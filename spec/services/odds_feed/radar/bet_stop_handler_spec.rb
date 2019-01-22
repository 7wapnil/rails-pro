describe OddsFeed::Radar::BetStopHandler do
  subject { described_class.new(payload) }

  let(:subject_with_input) { described_class.new(payload) }

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
      '<bet_stop timestamp="1532353934098" product="3" '\
      'event_id="sr:match:471123" groups="all"/>'
    )
  end

  let(:event) { create(:event, external_id: 'sr:match:471123') }

  it 'suspends event markets' do
    create_list(:market, 5, event: event, status: Market::ACTIVE)
    create_list(:market, 2, status: Market::ACTIVE) # other event

    subject.handle
    expect(Market.where(status: Market::SUSPENDED).count).to eq(5)
    expect(Market.where(status: Market::ACTIVE).count).to eq(2)
  end

  it 'deactivates event markets' do
    input_data = payload['bet_stop']
    input_data['market_status'] = 'deactivated'
    allow(subject_with_input).to receive(:input_data).and_return(input_data)

    create_list(:market, 5, event: event, status: Market::ACTIVE)
    create_list(:market, 2, status: Market::ACTIVE) # other event

    subject_with_input.handle
    expect(Market.where(status: Market::INACTIVE).count).to eq(5)
    expect(Market.where(status: Market::ACTIVE).count).to eq(2)
  end
end
