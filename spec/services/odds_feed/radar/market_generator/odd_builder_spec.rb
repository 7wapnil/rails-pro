# frozen_string_literal: true

describe OddsFeed::Radar::MarketGenerator::OddBuilder do
  subject { described_class.call(params) }

  let(:params) do
    {
      market: market,
      odd_data: odd_data,
      market_data: market_data
    }
  end

  let(:payload) do
    XmlParser
      .parse(file_fixture('odds_change_message.xml').read)
      .fetch('odds_change')
  end

  let(:event) { create(:event, external_id: payload['event_id']) }

  let(:market_payload) do
    payload.dig('odds', 'market').first
  end

  let(:market_data) do
    OddsFeed::Radar::MarketGenerator::MarketData.new(event, market_payload)
  end

  let(:odd_data) { market_data.outcome.first }
  let(:external_id) { "#{market.external_id}:#{odd_data['id']}" }
  let(:odd_name) { Faker::WorldOfWarcraft.name }

  let(:market) do
    Market.new(external_id: market_data.external_id,
               event_id: event.id,
               name: market_data.name,
               status: market_data.status,
               category: market_data.category)
  end

  before do
    create(:market_template, external_id: market_payload['id'])
    allow(market_data)
      .to receive(:odd_name)
      .with(odd_data['id'])
      .and_return(odd_name)
  end

  it 'builds odd with specific external id' do
    expect(subject.external_id).to eq(external_id)
  end

  it 'builds new odd with valid params' do
    expect(subject).to have_attributes(
      external_id: external_id,
      market_id: market.id,
      name: odd_name,
      status: Odd::ACTIVE,
      value: odd_data['odds'].to_f
    )
  end

  context 'when odds payload returns inactive odd' do
    before { odd_data['active'] = '0' }

    it 'builds new odd with inactive status' do
      expect(subject.status).to eq(Odd::INACTIVE)
    end
  end

  context 'when odds payload does not have value' do
    before { odd_data['odds'] = nil }

    context 'and odd with such external id does not exist' do
      it 'builds new odd with zero value' do
        expect(subject.value).to be_zero
      end
    end

    context 'and odd with such external id exists' do
      let!(:odd) { create(:odd, external_id: external_id) }

      it 'gives found odd but changes only its status' do
        expect(subject).to have_attributes(
          id: odd.id,
          status: Odd::ACTIVE,
          value: odd.value
        )
      end
    end
  end

  context 'when odds payload has zero value' do
    before { odd_data['odds'] = 0 }

    context 'and odd with such external id does not exist' do
      it 'builds new odd with zero value' do
        expect(subject.value).to be_zero
      end
    end

    context 'and odd with such external id exists' do
      let!(:odd) { create(:odd, external_id: external_id) }

      it 'gives found odd but changes only its status' do
        expect(subject).to have_attributes(
          id: odd.id,
          status: Odd::ACTIVE,
          value: odd.value
        )
      end
    end
  end
end
