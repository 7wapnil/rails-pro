# frozen_string_literal: true

describe OddsFeed::Radar::EventBasedCache::Writer do
  subject { described_class.call(event: event) }

  let(:competitors_count) { rand(2..5) }
  let(:competitors) do
    Array
      .new(competitors_count) { |index| { 'id' => "sr:competitor:#{index}" } }
  end

  let(:competitor_payload) do
    {
      'competitors' => { 'competitor' => competitors }
    }
  end

  let(:event) { build(:event, payload: competitor_payload) }

  it 'caches only competitors from payload' do
    expect(OddsFeed::Radar::Entities::CompetitorLoader)
      .to receive(:call)
      .exactly(competitors_count)
      .times

    subject
  end

  it 'caches exactly competitors from payload' do
    competitors.map.each do |competitor_payload|
      expect(OddsFeed::Radar::Entities::CompetitorLoader)
        .to receive(:call)
        .with(external_id: competitor_payload['id'])
    end

    subject
  end

  context 'with competitor payload as nil' do
    let(:competitor_payload) {}

    it 'works correct' do
      expect(OddsFeed::Radar::Entities::CompetitorLoader)
        .not_to receive(:call)
      subject
    end
  end

  context 'with competitor payload as empty array' do
    let(:competitor_payload) do
      { 'competitors' => { 'competitor' => [] } }
    end

    it 'works correct' do
      expect(OddsFeed::Radar::Entities::CompetitorLoader)
        .not_to receive(:call)
      subject
    end
  end

  context 'with competitor payload as attributes for one competitor' do
    let(:competitor_payload) do
      {
        'competitors' => {
          'competitor' => { 'id' => 'sr:competitor:2' }
        }
      }
    end

    it 'collects data for one competitor' do
      expect(OddsFeed::Radar::Entities::CompetitorLoader)
        .to receive(:call)
        .with(external_id: 'sr:competitor:2')
      subject
    end
  end
end
