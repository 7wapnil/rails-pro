describe Radar::LiveCoverageBookingWorker do
  subject { described_class.new }

  let(:match_id) { 'sr:match:14738223' }

  it 'calls coverage service' do
    expect(OddsFeed::Radar::LiveBookingService).to receive(:call)
    subject.perform(match_id)
  end
end
