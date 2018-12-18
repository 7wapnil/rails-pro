describe Radar::LiveCoverageBookingWorker do
  let(:match_id) { 'sr:match:14738223' }

  subject { Radar::LiveCoverageBookingWorker.new }

  it 'calls coverage service' do
    expect(OddsFeed::Radar::LiveBookingService).to receive(:call)
    subject.perform(match_id)
  end
end
