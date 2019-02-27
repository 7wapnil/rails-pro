describe OddsFeed::Radar::MarketGenerator::TemplateLoader do
  subject { described_class.new(*args) }

  let(:empty_cache) { {} }

  let!(:template) do
    create(:market_template,
           :with_outcome_data,
           specific_outcome_id: outcome['id'],
           specific_outcome_name: outcome['name'])
  end
  let(:variant_id) { rand(0..5) }
  let(:cache)      { empty_cache }
  let(:args)       { [template.external_id, variant_id, cache] }

  let(:payload) do
    XmlParser.parse(
      file_fixture('radar_markets_description_for_variant.xml').read
    )
  end

  let(:outcomes) do
    payload.dig('market_descriptions', 'market')['outcomes']
  end
  let(:outcome) { outcomes['outcome'].first }

  describe '#market_name' do
    it { expect(subject.market_name).to eq(template.name) }
  end

  describe '#odd_name' do
    let(:name)      { Faker::WorldOfWarcraft.hero }
    let(:player_id) { 'sr:player:1234' }

    context 'player odd payload' do
      let(:subject_with_template) { described_class.new(*args) }

      before do
        expect(OddsFeed::Radar::Entities::PlayerLoader)
          .to receive(:call).with(external_id: player_id).and_return(name)

        allow(subject_with_template).to receive(:find_odd_template)
      end

      it { expect(subject_with_template.odd_name(player_id)).to eq(name) }
    end

    context 'payload from loaded template' do
      let(:variant_id) {}
      let(:template) do
        create(:market_template, payload: { outcomes: outcomes })
      end

      before do
        expect_any_instance_of(OddsFeed::Radar::Client)
          .not_to receive(:market_variants)
      end

      it { expect(subject.odd_name(outcome['id'])).to eq(outcome['name']) }
    end

    context 'payload from Radar API' do
      let(:cache_settings) do
        {
          cache: { expires_in: OddsFeed::Radar::Client::DEFAULT_CACHE_TERM }
        }
      end

      before do
        template.update(payload: { 'outcomes' => nil })
        expect_any_instance_of(OddsFeed::Radar::Client)
          .to receive(:market_variants)
          .and_return(payload)
      end

      it { expect(subject.odd_name(outcome['id'])).to eq(outcome['name']) }
    end

    context 'template not found' do
      let(:external_id) { Faker::Bank.account_number }
      let(:message)     { "Odd template ID #{external_id} not found" }
      let(:subject_with_template) { described_class.new(*args) }

      before { expect(subject_with_template).to receive(:find_odd_template) }

      it do
        expect { subject_with_template.odd_name(external_id) }
          .to raise_error(StandardError, message)
      end
    end

    context 'template loader receives cached market templates' do
      let(:cache) do
        { market_templates_cache: { template.external_id.to_sym => template } }
      end

      let(:market_name) { subject.market_name }

      before do
        allow(MarketTemplate).to receive(:find_by!)
        market_name
      end

      it('takes market from cache') { expect(market_name).to eq template.name }

      it 'does not call real model' do
        expect(MarketTemplate).not_to have_received(:find_by!)
      end
    end

    context 'when cache is empty' do
      let(:cache) { nil }

      before do
        allow(MarketTemplate).to receive(:find_by!).and_return(template)
        subject.market_name
      end

      it 'fallbacks to active record call' do
        expect(MarketTemplate).to have_received(:find_by!).once
      end
    end
  end
end
