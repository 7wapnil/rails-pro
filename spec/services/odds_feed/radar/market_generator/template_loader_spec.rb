describe OddsFeed::Radar::MarketGenerator::TemplateLoader do
  subject { described_class.new(*args) }

  let(:template)   { create(:market_template) }
  let(:variant_id) { rand(0..5) }
  let(:args)       { [template.external_id, variant_id] }

  let(:payload) do
    XmlParser.parse(
      file_fixture('radar_markets_description_for_variant.xml').read
    )
  end
  let(:outcomes) do
    payload.dig('market_descriptions', 'market')['outcomes']
  end

  describe '#market_name' do
    it { expect(subject.market_name).to eq(template.name) }
  end

  describe '#odd_name' do
    let(:name)      { Faker::WorldOfWarcraft.hero }
    let(:player_id) { 'sr:player:1234' }
    let(:outcome)   { outcomes['outcome'].first }

    context 'player odd payload' do
      before do
        expect(OddsFeed::Radar::Entities::PlayerLoader)
          .to receive(:call).with(external_id: player_id).and_return(name)

        allow(subject).to receive(:find_odd_template)
      end

      it { expect(subject.odd_name(player_id)).to eq(name) }
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
      before do
        expect_any_instance_of(OddsFeed::Radar::Client)
          .to receive(:market_variants)
          .with(template.external_id, variant_id)
          .and_return(payload)
      end

      it { expect(subject.odd_name(outcome['id'])).to eq(outcome['name']) }
    end

    context 'template not found' do
      let(:external_id) { Faker::Bank.account_number }
      let(:message)     { "Odd template ID #{external_id} not found" }

      before { expect(subject).to receive(:find_odd_template) }

      it do
        expect { subject.odd_name(external_id) }
          .to raise_error(StandardError, message)
      end
    end
  end
end
