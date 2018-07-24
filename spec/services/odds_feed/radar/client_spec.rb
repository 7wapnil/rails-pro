describe OddsFeed::Radar::Client do
  context 'client api' do
    let(:options) do
      { headers: { "x-access-token": ENV['RADAR_API_TOKEN'],
                   "content-type": 'application/xml' } }
    end
    let(:route) { nil }

    before do
      allow(subject.class)
        .to receive(:get)
        .with(route, options)
        .and_return(OpenStruct.new(parsed_response: ''))
    end

    context 'who am i request' do
      let(:route) { '/users/whoami.xml' }

      it 'should request whoami endpoint' do
        subject.who_am_i
      end
    end

    context 'event request' do
      let(:event_id) { 'sr:match:10001' }
      let(:route) { "/sports/en/sport_events/#{event_id}/fixture.xml" }

      it 'should return adapter on event request' do
        expect(subject.event(event_id))
          .to be_a(OddsFeed::Radar::EventAdapter)
      end
    end
  end
end
