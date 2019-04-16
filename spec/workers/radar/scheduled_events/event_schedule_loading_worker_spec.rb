# frozen_string_literal: true

describe Radar::ScheduledEvents::EventScheduleLoadingWorker do
  subject { described_class.new }

  let(:date) { Date.current }
  let(:timestamp) { date.to_datetime.to_i }

  let(:perform_job) { subject.perform(timestamp) }

  include_context 'events for specific date' do
    let(:mocked_date) { date }
  end

  before do
    allow(Rails.cache).to receive(:write_multi)
    allow(EventScope).to receive(:import)
  end

  it 'imports event scopes' do
    perform_job
    expect(EventScope).to have_received(:import).exactly(6).times
  end

  context 'with players' do
    let(:cached_data) do
      {
        'entity-names:sr:player:1' => 'Ryan Donato',
        'entity-names:sr:player:2' => 'Matt Read',
        'entity-names:sr:player:3' => 'Joel Edmundson',
        'entity-names:sr:player:4' => 'Patrick Maroon',
        'entity-names:sr:player:5' => 'Mohamed Saleh',
        'entity-names:sr:player:6' => 'Hassan Madhafar',
        'entity-names:sr:player:7' => 'Mohammed Mubarak',
        'entity-names:sr:player:8' => 'Samba Diarra Tounkara'
      }
    end

    it 'caches them' do
      expect(Rails.cache)
        .to receive(:write_multi)
        .with(
          cached_data,
          cache: {
            expires_in: OddsFeed::Radar::Entities::BaseLoader::CACHE_TERM
          }
        )

      perform_job
    end
  end

  context 'with competitors' do
    let(:cached_data) do
      {
        'entity-names:sr:competitor:1' => 'Minnesota Wild',
        'entity-names:sr:competitor:2' => 'St. Louis Blues',
        'entity-names:sr:competitor:3' => 'Al Orouba (Oma)',
        'entity-names:sr:competitor:4' => 'Sur'
      }
    end

    it 'caches them' do
      expect(Rails.cache)
        .to receive(:write_multi)
        .with(
          cached_data,
          cache: {
            expires_in: OddsFeed::Radar::Entities::BaseLoader::CACHE_TERM
          }
        )

      perform_job
    end
  end
end
