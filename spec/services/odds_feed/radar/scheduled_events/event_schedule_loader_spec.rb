# frozen_string_literal: true

describe OddsFeed::Radar::ScheduledEvents::EventScheduleLoader do
  subject { service_object.call }

  let(:service_object) do
    described_class.new(timestamp: timestamp, range: 0.days)
  end

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
    allow(::Radar::ScheduledEvents::EventLoadingWorker)
      .to receive(:perform_async)
    allow(ScopedEvent).to receive(:import)
    allow(service_object).to receive(:log_job_message)

    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:events_for_date)
      .and_return(event_adapters)

    event_adapters.each do |adapter|
      allow(adapter.result)
        .to receive(:[])
        .with(:external_id)
        .and_return(adapter.external_id)
    end
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
        "Event based data caching for #{humanized_date} was scheduled."
      )

    subject
  end

  context 'import' do
    before { subject }

    it 'schedules a loading worker for each event' do
      expect(::Radar::ScheduledEvents::EventLoadingWorker)
        .to have_received(:perform_async)
        .exactly(events.size)
        .times
    end

    it 'gets external_id from events' do
      event_adapters.each do |event|
        expect(event.result)
          .to have_received(:[])
          .with(:external_id)
          .once
      end
    end
  end
end
