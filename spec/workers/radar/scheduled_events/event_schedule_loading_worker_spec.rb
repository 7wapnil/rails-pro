# frozen_string_literal: true

describe Radar::ScheduledEvents::EventScheduleLoadingWorker do
  subject { described_class.new }

  let(:date) { Date.current }
  let(:timestamp) { date.to_datetime.to_i }

  let(:perform_job) { subject.perform }

  include_context 'events for specific date' do
    let(:mocked_date) { date }
  end

  before do
    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:events_for_date)
  end

  xit 'implement tests here' do
  end
end
