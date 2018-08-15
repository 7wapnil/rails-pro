describe Radar::EventProcessingWorker do
  let(:payload) { { test: 1 }.stringify_keys }

  it { is_expected.to be_processed_in :default }

  it 'sends payload to odds feed service' do
    allow(OddsFeed::Radar::OddsChangeHandler).to receive(:new)
    Radar::EventProcessingWorker.new.perform(payload)
    expect(OddsFeed::Radar::OddsChangeHandler)
      .to have_received(:new)
      .with(payload)
  end
end
