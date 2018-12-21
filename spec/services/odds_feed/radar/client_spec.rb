describe OddsFeed::Radar::Client do
  let(:headers) { { "x-access-token": 'test-api-token' } }
  let!(:api_domain) { 'https://test-api-domain' }

  before do
    described_class.base_uri(api_domain)
    described_class.headers(headers)
  end

  context 'routes' do
    it 'requests whoami endpoint' do
      body = file_fixture('api/who_am_i_response.xml').read

      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 200, body: body)

      subject.who_am_i
    end

    it 'returns adapter on event request' do
      event_id = 'sr:match:10001'
      route = "#{api_domain}/sports/en/sport_events/#{event_id}/fixture.xml"
      stub_request(:any, route)
        .with(headers: headers)
        .to_return(body: '')

      expect(subject.event(event_id)).to be_a(OddsFeed::Radar::EventAdapter)
    end
  end

  context 'unexpected responses' do
    let(:forbidden_response) do
      file_fixture('api/forbidden_response.xml').read
    end
    let(:invalid_xml) { '<doctype><html><body>Hello World</body></html>' }

    it 'raise error on 403' do
      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 403, body: forbidden_response)

      expect { subject.who_am_i }.to raise_error(HTTParty::ResponseError)
    end

    it 'raises error on invalid xml' do
      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 200, body: invalid_xml)

      expect { subject.who_am_i }
        .to raise_error(HTTParty::ResponseError, 'Malformed response body')
    end

    it 'raises error on plain text' do
      stub_request(:any, "#{api_domain}/users/whoami.xml")
        .with(headers: headers)
        .to_return(status: 200, body: 'Plain text')

      expect { subject.who_am_i }
        .to raise_error(HTTParty::ResponseError, 'Malformed response body')
    end
  end
end
