# frozen_string_literal: true

describe OddsFeed::Radar::ScheduledEvents::DateEventsLoader do
  subject { service_object.call }

  let(:service_object) { described_class.new(timestamp: timestamp) }

  let(:date) { Date.current }
  let(:timestamp) { date.to_datetime.to_i }
  let(:humanized_date) { I18n.l(date, format: :informative) }

  let(:events_count) { rand(2..4) }
  let(:event_scopes) { build_list(:event_scope, rand(1..3)) }
  let(:events) { build_list(:event, events_count, event_scopes: event_scopes) }
  let(:scoped_events) { events.flat_map(&:scoped_events) }
  let(:event_adapters) do
    events.map { |event| OpenStruct.new(result: event) }
  end

  let(:events_cache_data) do
    Array.new(events_count) do
      {
        competitors: {
          entity_name(:competitor) => Faker::Superhero.name,
          entity_name(:competitor) => Faker::Superhero.name
        },
        players: {
          entity_name(:player) => Faker::WorldOfWarcraft.hero,
          entity_name(:player) => Faker::WorldOfWarcraft.hero
        }
      }
    end
  end

  include_context 'events for specific date' do
    let(:mocked_date) { date }
  end

  def entity_name(name)
    "entity-names:sr:#{name}:#{Time.zone.now.to_i}"
  end

  before do
    allow(Rails.cache).to receive(:write_multi)
    allow(Event).to receive(:import)
    allow(ScopedEvent).to receive(:import)
    allow(service_object).to receive(:log_job_message)

    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:events_for_date)
      .and_return(event_adapters)

    allow(OddsFeed::Radar::EventBasedCache::Collector)
      .to receive(:call)
      .and_return(*events_cache_data)
  end

  it 'logs start of the process' do
    expect(service_object)
      .to receive(:log_job_message)
      .with(
        :info,
        "Event based data for #{humanized_date} was received from response."
      )

    subject
  end

  it 'logs successful ending of the process' do
    expect(service_object)
      .to receive(:log_job_message)
      .with(
        :info,
        "Event based data for #{humanized_date} was cached successfully."
      )

    subject
  end

  context 'import' do
    before { subject }

    it 'imports events' do
      expect(Event)
        .to have_received(:import)
        .with(events, hash_including(validate: false))
    end

    it 'imports event scopes' do
      expect(ScopedEvent)
        .to have_received(:import)
        .with(scoped_events, hash_including(validate: false))
    end
  end

  context 'with players' do
    let(:players) do
      events_cache_data
        .reduce({}) { |hash, data| hash.deep_merge(data[:players]) }
    end

    before { subject }

    it 'caches them' do
      expect(Rails.cache)
        .to have_received(:write_multi)
        .with(
          players,
          cache: {
            expires_in: OddsFeed::Radar::Entities::BaseLoader::CACHE_TERM
          }
        )
    end
  end

  context 'with competitors' do
    let(:competitors) do
      events_cache_data
        .reduce({}) { |hash, data| hash.deep_merge(data[:competitors]) }
    end

    before { subject }

    it 'caches them' do
      expect(Rails.cache)
        .to have_received(:write_multi)
        .with(
          competitors,
          cache: {
            expires_in: OddsFeed::Radar::Entities::BaseLoader::CACHE_TERM
          }
        )
    end
  end

  context 'on error' do
    let(:error) { PG::ConnectionBad.new(Faker::WorldOfWarcraft.quote) }

    before { allow(ScopedEvent).to receive(:import).and_raise(error) }

    it 'raises original error' do
      expect { subject }.to raise_error(error)
    end

    it 'logs an exception' do
      allow(service_object).to receive(:raise)
      expect(service_object)
        .to receive(:log_job_message)
        .with(:fatal, "Event based data for #{humanized_date} was not cached.")

      subject
    end
  end
end
