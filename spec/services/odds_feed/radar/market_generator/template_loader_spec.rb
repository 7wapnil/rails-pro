# frozen_string_literal: true

describe OddsFeed::Radar::MarketGenerator::TemplateLoader do
  subject { described_class.new(*args) }

  let(:empty_cache) { {} }

  let!(:template) do
    create(:market_template,
           :with_outcome_data,
           specific_outcome_id: outcome['id'],
           specific_outcome_name: outcome['name'])
  end
  let(:variant_id) { rand(0..5).to_s }
  let(:args)       { [template, variant_id] }

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

    context 'variant payload from loaded template' do
      let(:variant_name) { Faker::WorldOfWarcraft.hero }

      before do
        template.update(
          payload: {
            variants: true,
            variant_id => {
              outcomes: {
                outcome: [{
                  id: outcome['id'],
                  name: variant_name
                }]
              }
            }
          }
        )
      end

      it 'does not call Radar API and returns valid outcome name' do
        expect(subject.odd_name(outcome['id'])).to eq(variant_name)
      end
    end

    context 'payload from Radar API' do
      before do
        template.update(
          payload: {
            outcomes: nil,
            variants: true
          }
        )
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
  end
end
