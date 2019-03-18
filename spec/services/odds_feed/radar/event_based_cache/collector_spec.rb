# frozen_string_literal: true

describe OddsFeed::Radar::EventBasedCache::Collector do
  subject { described_class.call(event: event) }

  let(:competitor_payload) do
    {
      'competitors' => {
        'competitor' => [
          { 'id' => 'sr:competitor:1' },
          { 'id' => 'sr:competitor:2' }
        ]
      }
    }
  end

  let(:event) { build(:event, payload: competitor_payload) }

  let(:cache_data) do
    {
      'sr:competitor:1' => {
        competitors: {
          'entity-names:sr:competitor:1' => Faker::Superhero.name
        },
        players: {
          'entity-names:sr:player:1' => Faker::Superhero.name,
          'entity-names:sr:player:2' => Faker::Superhero.name,
          'entity-names:sr:player:3' => Faker::Superhero.name
        }
      },
      'sr:competitor:2' => {
        competitors: {
          'entity-names:sr:competitor:2' => Faker::Superhero.name
        },
        players: {
          'entity-names:sr:player:4' => Faker::Superhero.name
        }
      }
    }
  end

  let(:all_collected_data) do
    cache_data
      .values
      .reduce({}) { |hash, collected_data| hash.deep_merge(collected_data) }
  end

  before do
    allow(OddsFeed::Radar::Entities::CompetitorLoader)
      .to receive(:call)
      .with(external_id: 'sr:competitor:1', collect_only: true)
      .and_return(cache_data['sr:competitor:1'])

    allow(OddsFeed::Radar::Entities::CompetitorLoader)
      .to receive(:call)
      .with(external_id: 'sr:competitor:2', collect_only: true)
      .and_return(cache_data['sr:competitor:2'])
  end

  it 'takes all collected data together' do
    expect(subject).to eq(all_collected_data)
  end

  context 'with competitor payload as nil' do
    let(:competitor_payload) {}

    it 'works correct' do
      expect(subject).to eq({})
    end
  end

  context 'with competitor payload as empty array' do
    let(:competitor_payload) do
      { 'competitors' => { 'competitor' => [] } }
    end

    it 'works correct' do
      expect(subject).to eq({})
    end
  end

  context 'with competitor payload as attributes for one competitor' do
    let(:competitor_payload) do
      {
        'competitors' => {
          'competitor' => { 'id' => 'sr:competitor:1' }
        }
      }
    end

    it 'collects data for one competitor' do
      expect(subject).to eq(cache_data['sr:competitor:1'])
    end
  end
end
