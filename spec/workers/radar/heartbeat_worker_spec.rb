describe Radar::HeartbeatWorker do
  let(:payload) { 'any' }

  it { is_expected.to be_processed_in :critical }

  xit 'passes payload with OddsFeed::Radar::AliveHandler'
  it 'handles with OddsFeed::Radar::AliveHandler' do
    allow_any_instance_of(OddsFeed::Radar::AliveHandler)
      .to receive(:handle).and_return(:handled)
    expect(subject.perform(payload)).to eq :handled
  end
end
