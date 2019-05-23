# frozen_string_literal: true

describe OddsFeed::Radar::MarketGenerator::TemplateLoader do
  subject { described_class.new(*args) }

  let(:empty_cache) { {} }

  let(:event) { create(:event) }
  let!(:template) do
    create(:market_template,
           :with_outcome_data,
           specific_outcome_id: outcome['id'],
           specific_outcome_name: outcome['name'])
  end
  let(:variant_id) { rand(0..5).to_s }
  let(:args)       { [event, template, variant_id] }

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
    context 'player odd payload' do
      let(:subject_with_template) { described_class.new(*args) }

      it 'generates odd name from a competing player name' do
        player_id = 'sr:player:1234'
        player = create(:player, external_id: player_id)
        competitor = create(:competitor)
        competitor.players << player
        event.competitors << competitor

        allow(subject_with_template).to receive(:find_odd_template)

        expect(subject_with_template.odd_name(player_id))
          .to eq(player.full_name)
      end

      it 'generates odd name from a player loaded from API' do
        player_payload = {
          'player_profile' => {
            'player' => {
              'id' => 'sr:player:903786',
              'name' => 'Pezzella, Giuseppe',
              'full_name' => 'Giuseppe Pezzella',
              'type' => 'defender',
              'date_of_birth' => '1997-11-29',
              'nationality' => 'Italy',
              'country_code' => 'ITA',
              'height' => '187',
              'weight' => '85',
              'gender' => 'male'
            }
          }
        }

        allow(subject_with_template).to receive(:find_odd_template)

        allow_any_instance_of(OddsFeed::Radar::Client)
          .to receive(:player_profile)
          .with('sr:player:903786')
          .and_return(player_payload)

        expect(subject_with_template.odd_name('sr:player:903786'))
          .to eq('Giuseppe Pezzella')
      end
    end

    context 'payload from loaded template' do
      let(:name) { Faker::WorldOfWarcraft.hero }
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
      let(:message)     { 'Odd template not found' }
      let(:subject_with_template) { described_class.new(*args) }

      before do
        expect(subject_with_template).to receive(:find_odd_template)
        allow(Rails.logger)
          .to receive(:error)
          .with(message: message, external_id: external_id)
      end

      it do
        expect { subject_with_template.odd_name(external_id) }
          .to raise_error(StandardError)
      end

      it 'logs the failure' do
        subject_with_template.odd_name(external_id)
        raise
      rescue StandardError
        expect(Rails.logger)
          .to have_received(:error)
          .with(message: message, external_id: external_id)
      end
    end
  end
end
