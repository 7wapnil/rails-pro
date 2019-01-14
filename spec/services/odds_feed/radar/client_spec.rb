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

  describe '#product_recovery_initiate_request' do
    let(:recover_after) { Faker::Time.backward(2) }
    let(:product_code) { Faker::Lorem.word.to_sym }

    before do
      allow(subject).to receive(:log_job_message)
      allow(subject).to receive(:post)
    end

    context 'with requires arguments only' do
      let(:expected_path) do
        "/#{product_code}/recovery/initiate_request?after=#{recover_after.to_i}"
      end

      before do
        subject.product_recovery_initiate_request(
          product_code: product_code, after: recover_after
        )
      end

      it 'logs job message' do
        log_message = "Calling subscription recovery on #{expected_path}"
        expect(subject).to have_received(:log_job_message)
          .with(:info, log_message).once
      end
      it 'post to correct path' do
        expect(subject).to have_received(:post)
          .with(expected_path).once
      end
    end

    context 'with all options provided' do
      let(:request_id) { Faker::Number.number(4) }
      let(:node_id) { Faker::Number.number(4) }

      let(:expected_path) do
        query_string = [
          "after=#{recover_after.to_i}",
          "node_id=#{node_id}",
          "request_id=#{request_id}"
        ].join('&')
        "/#{product_code}/recovery/initiate_request?#{query_string}"
      end

      before do
        subject.product_recovery_initiate_request(
          product_code: product_code, after: recover_after,
          request_id: request_id, node_id: node_id
        )
      end

      it 'logs job message' do
        log_message = "Calling subscription recovery on #{expected_path}"
        expect(subject).to have_received(:log_job_message)
          .with(:info, log_message).once
      end
      it 'post to correct path' do
        expect(subject).to have_received(:post)
          .with(expected_path).once
      end
    end
  end
end
