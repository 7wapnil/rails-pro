describe OddsFeed::Radar::MarketGenerator::OddsGenerator do
  subject { described_class.call(market, market_data) }

  let(:market) { build_stubbed(:market) }
  let(:event)  { build_stubbed(:event) }

  let(:market_data) do
    OddsFeed::Radar::MarketGenerator::MarketData.new(event, payload)
  end

  let(:payload) do
    XmlParser
      .parse(file_fixture('odds_change_message.xml').read)
      .dig('odds_change', 'odds', 'market')
      .last
  end

  let(:odds_count) { payload['outcome'].length }

  before { allow(market_data).to receive(:odd_name).and_return(:name) }

  context 'build all odds' do
    it { expect(subject.length).to eq(odds_count) }
  end

  context 'invalid data' do
    let(:invalid_odds_count) { rand(odds_count) }
    let(:valid_odds_count)   { odds_count - invalid_odds_count }

    context 'with outcome missing' do
      before { payload['outcome'] = '' }

      it { expect(subject).to be_empty }
    end

    context 'ignore odds with zero value' do
      before do
        invalid_odds_count
          .times
          .each { |offset| payload.dig('outcome', offset).delete('odds') }
      end

      it { expect(subject.length).to eq(valid_odds_count) }
    end

    context 'ignore invalid odds' do
      let(:invalid_names) { Array.new(invalid_odds_count) }
      let(:valid_names) do
        Array.new(valid_odds_count) { Faker::WorldOfWarcraft.name }
      end
      let(:names) { [*invalid_names, *valid_names] }

      before do
        allow(market_data)
          .to receive(:odd_name)
          .and_return(*names)
      end

      it { expect(subject.length).to eq(valid_odds_count) }
    end

    context 'ignore when `odd_data` is not a payload' do
      before do
        invalid_odds_count
          .times
          .each { |offset| payload.dig('outcome')[offset] = '' }
      end

      it { expect(subject.length).to eq(valid_odds_count) }
    end
  end
end
