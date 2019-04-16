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
    allow(EventScope).to receive(:import)
  end

  it 'imports event scopes' do
    perform_job
    expect(EventScope).to have_received(:import).exactly(6).times
  end
end
