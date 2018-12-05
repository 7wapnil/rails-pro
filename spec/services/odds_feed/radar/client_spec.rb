describe OddsFeed::Radar::Client do
  context 'client api' do
    let(:options) do
      { headers: { "x-access-token": ENV['RADAR_API_TOKEN'] } }
    end
    let(:route) { nil }

    before do
      allow(subject.class)
        .to receive(:get)
        .with(route, options)
        .and_return(OpenStruct.new(
                      parsed_response: {
                        'fixtures_fixture' => {
                          'fixture' => ''
                        }
                      }
                    ))
    end

    context 'error response' do
      let(:route) { '/users/whoami.xml' }

      before do
        allow(subject.class)
          .to receive(:get)
          .with(route, options)
          .and_return(OpenStruct.new(
                        parsed_response: {
                          'error' => {
                            'message' => 'Unexpected error.'
                          }
                        }
                      ))
      end

      it 'requests whoami endpoint' do
        expect { subject.who_am_i }
          .to raise_error(OddsFeed::InvalidResponseError, 'Unexpected error.')
      end
    end

    context 'who am i request' do
      let(:route) { '/users/whoami.xml' }

      it 'requests whoami endpoint' do
        subject.who_am_i
      end
    end

    context 'event request' do
      let(:event_id) { 'sr:match:10001' }
      let(:route) { "/sports/en/sport_events/#{event_id}/fixture.xml" }

      it 'returns adapter on event request' do
        expect(subject.event(event_id))
          .to be_a(OddsFeed::Radar::EventAdapter)
      end
    end

    context 'markets request' do
      let(:route) { '/descriptions/en/markets.xml?include_mappings=false' }

      it 'returns markets request result' do
        subject.markets
      end
    end
  end
end
