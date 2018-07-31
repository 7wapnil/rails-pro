describe Radar::HeartbeatWorker do
  let(:payload) { 'any' }

  it { is_expected.to be_processed_in :critical }

  it 'handles with OddsFeed::Radar::AliveHandler' do
    expect_any_instance_of(OddsFeed::Radar::AliveHandler)
      .to receive(:handle)

    subject.perform(payload)
  end

  it 'passes payload to OddsFeed::Radar::AliveHandler' do
    expect(OddsFeed::Radar::AliveHandler)
      .to receive(:new)
      .with(payload)
      .and_return(OpenStruct.new(handle: nil))

    subject.perform(payload)
  end
end
