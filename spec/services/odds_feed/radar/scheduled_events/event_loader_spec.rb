describe OddsFeed::Radar::ScheduledEvents::EventLoader do
  subject { service_object.call }

  let(:event_id) { 'sr:match:64600' }
  let(:service_object) { described_class.new(event_id) }
  let(:mock) { instance_double('loader') }

  before do
    allow(EventsManager::EventLoader)
      .to receive(:new)
      .with(event_id)
      .and_return(mock)
    allow(mock).to receive(:call)
  end

  context 'calling EventLoader' do
    before do
      subject
    end

    it 'calls EventLoader for given event_id' do
      expect(mock).to have_received(:call)
    end
  end

  context 'logging start' do
    before do
      allow(service_object)
        .to receive(:log_job_message)
    end

    it 'logs event loading start' do
      subject
      expect(service_object)
        .to have_received(:log_job_message)
        .with(:info, "Starting loading Event##{event_id}")
        .once
    end
  end

  context 'logging success' do
    before do
      allow(service_object)
        .to receive(:log_job_message)
    end

    it 'logs event loading success' do
      subject
      expect(service_object)
        .to have_received(:log_job_message)
        .with(:info, "Loaded Event##{event_id} successfully.")
        .once
    end
  end

  context 'logging failure' do
    before do
      allow(service_object)
        .to receive(:log_job_message)
      allow(mock).to receive(:call).and_raise(StandardError)
    end

    it 'raises error' do
      expect { subject }.to raise_error(StandardError)
    end

    it 'logs event loading failure with fatal level' do
      subject
      raise
    rescue StandardError
      expect(service_object)
        .to have_received(:log_job_message)
        .with(:error, "Failed to load Event##{event_id}.")
        .once
    end
  end
end