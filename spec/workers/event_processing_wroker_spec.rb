describe EventProcessingWorker do
  let(:payload) { { test: 1 }.stringify_keys }

  it 'should send payload to odds feed service' do
    allow(OddsFeed::Service).to receive(:call)
    EventProcessingWorker.new.perform(payload)
    expect(OddsFeed::Service)
      .to have_received(:call)
      .with(instance_of(OddsFeed::Radar::Client), payload)
  end
end
