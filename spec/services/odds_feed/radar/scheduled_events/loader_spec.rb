# frozen_string_literal: true

describe OddsFeed::Radar::ScheduledEvents::Loader do
  subject { described_class.call(params) }

  let(:date_offset) { rand(1..3).days }
  let(:from_date) { rand(5..8).days.ago.to_date }
  let(:to_date) { from_date + date_offset }

  let(:params) do
    {
      from_date: from_date,
      offset: date_offset
    }
  end

  let(:offset) { described_class::OFFSET_BETWEEN_BATCHES }
  let(:arguments_for_workers) do
    (from_date..to_date)
      .map
      .with_index { |date, index| [index * offset, date.to_datetime.to_i] }
      .to_h
  end

  before do
    allow(::Radar::ScheduledEvents::DateEventsLoadingWorker)
      .to receive(:perform_in)
  end

  it 'creates jobs to load events for passed amount of days with interval' do
    subject

    arguments_for_workers.each do |time_to_call, timestamp|
      expect(::Radar::ScheduledEvents::DateEventsLoadingWorker)
        .to have_received(:perform_in)
        .with(time_to_call, timestamp)
        .once
    end
  end

  context 'without passed arguments' do
    let(:params) { {} }
    let(:from_date) { Date.current }
    let(:to_date) { from_date + described_class::DEFAULT_RANGE }

    let(:arguments_for_workers) do
      (from_date..to_date)
        .map
        .with_index { |date, index| [index * offset, date.to_datetime.to_i] }
        .to_h
    end

    before { subject }

    it 'creates jobs to preload events for 4 days including today one by one' do
      arguments_for_workers.each do |time_to_call, timestamp|
        expect(::Radar::ScheduledEvents::DateEventsLoadingWorker)
          .to have_received(:perform_in)
          .with(time_to_call, timestamp)
          .once
      end
    end
  end
end
