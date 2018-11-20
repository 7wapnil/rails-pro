describe Radar::LiveCoverageBookingWorker do
  subject { Radar::LiveCoverageBookingWorker.new }

  let(:match_id) { 'sr:match:14738223' }
  let(:api) { OddsFeed::Radar::Client }

  it 'raises an error when event is not found' do
    expect { subject.perform(match_id) }
      .to raise_error ActiveRecord::RecordNotFound
  end

  context 'event present' do
    let(:event) { create(:event, external_id: match_id) }

    before do
      allow(Event).to receive(:find_by!) { event }

      allow_any_instance_of(api)
        .to receive(:book_live_coverage)
        .with(match_id)
        .and_return('response' => { 'response_code' => 'hello' })
    end

    after do
      subject.perform(match_id)
    end

    xit 'calls event booking API' do
      expect_any_instance_of(api)
        .to receive(:book_live_coverage)
        .with(match_id)
    end

    it 'updates :traded_live attribute on successful booking' do
      allow_any_instance_of(api)
        .to receive(:book_live_coverage)
        .with(match_id)
        .and_return('response' => { 'response_code' => 'OK' })

      expect(event).to receive(:update_attributes!).with(traded_live: true)
    end

    xit 'doesn\'t update :traded_live attribute on unsuccessful booking' do
      expect(event).not_to receive(:update_attributes!).with(traded_live: true)
    end
  end
end
