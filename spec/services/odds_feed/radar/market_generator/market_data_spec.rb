describe OddsFeed::Radar::MarketGenerator::MarketData do
  subject { described_class.new(event, payload, market_template) }

  let(:event) { build_stubbed(:event) }

  let(:payload) do
    XmlParser.parse(file_fixture('odds_change_message.xml').read)
             .dig('odds_change', 'odds', 'market')
             .first
  end
  let(:market_template) do
    create(:market_template, external_id: payload['id'])
  end

  describe '#name' do
    let(:market_name) { Faker::Science.element }
    let(:name)        { Faker::WorldOfWarcraft.hero }

    before do
      allow_any_instance_of(OddsFeed::Radar::MarketGenerator::TemplateLoader)
        .to receive(:market_name)
        .and_return(market_name)

      allow_any_instance_of(OddsFeed::Radar::Transpiling::Interpreter)
        .to receive(:parse)
        .with(market_name)
        .and_return(name)
    end

    it { expect(subject.name).to eq(name) }
  end

  describe '#odd_name' do
    let(:template_odd_name) { Faker::Number.number(4) }
    let(:external_id)       { 'sr:competitor:1234' }
    let(:odd_name)          { Faker::Number.number(4) }

    before do
      allow_any_instance_of(OddsFeed::Radar::MarketGenerator::TemplateLoader)
        .to receive(:odd_name)
        .and_return(template_odd_name)

      allow_any_instance_of(OddsFeed::Radar::Transpiling::Interpreter)
        .to receive(:parse)
        .with(template_odd_name)
        .and_return(odd_name)
    end

    it { expect(subject.odd_name(odd_name)).to eq(odd_name) }
  end

  describe '#external_id' do
    before do
      allow(OddsFeed::Radar::ExternalId)
        .to receive(:generate)
        .and_return(market_template.external_id)
    end

    it { expect(subject.external_id).to eq(market_template.external_id) }

    it 'builds correct generator' do
      subject.external_id

      expect(OddsFeed::Radar::ExternalId)
        .to have_received(:generate)
        .with(
          event_id: event.external_id,
          market_id: market_template.external_id,
          specs: payload['specifiers']
        )
    end
  end

  describe '#specifiers' do
    let(:specifiers) { payload['specifiers'] }

    it { expect(subject.specifiers).to eq(specifiers) }

    context 'returns empty string by default' do
      before { payload.delete('specifiers') }

      it { expect(subject.specifiers).to eq('') }
    end
  end

  describe '#status' do
    before { payload['status'] = '-1' }

    it { expect(subject.status).to eq(:suspended) }

    context 'returns default status' do
      before { payload.delete('status') }

      it { expect(subject.status).to eq(Market::DEFAULT_STATUS) }
    end
  end

  describe '#outcome' do
    let(:outcome) { payload['outcome'] }

    it { expect(subject.outcome).to eq(outcome) }
  end

  describe '#template' do
    it do
      expect(subject.template)
        .to be_a(OddsFeed::Radar::MarketGenerator::TemplateLoader)
    end
  end
end
