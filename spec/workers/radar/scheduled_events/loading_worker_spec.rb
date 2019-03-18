# frozen_string_literal: true

describe Radar::ScheduledEvents::LoadingWorker do
  subject { described_class.new }

  let(:loaded_days_count) do
    OddsFeed::Radar::ScheduledEvents::Loader::DEFAULT_RANGE.parts[:days] + 1
  end

  before do
    allow(::Radar::ScheduledEvents::DateEventsLoadingWorker)
      .to receive(:perform_in)

    subject.perform
  end

  it 'creates jobs to preload scheduled events for 4 days' do
    expect(::Radar::ScheduledEvents::DateEventsLoadingWorker)
      .to have_received(:perform_in)
      .exactly(loaded_days_count)
      .times
  end
end
